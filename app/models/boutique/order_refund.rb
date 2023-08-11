# frozen_string_literal: true

class Boutique::OrderRefund < Boutique::ApplicationRecord
  include Folio::HasAasmStates
  include Folio::HasSecretHash

  PAYMENT_METHODS = %w[
    PAYMENT_CARD
    BANK_ACCOUNT
    PAYPAL
    VOUCHER
  ]

  belongs_to :order, class_name: "Boutique::Order", foreign_key: :boutique_order_id, inverse_of: :refunds

  delegate :user,
           :email,
           :site,
           :currency_unit,
           :currency_code,
           :subscription,
           :primary_address,
           :secondary_address,
           :full_name,
           to: :order

  scope :ordered, -> { order(approved_at: :desc, id: :desc) }
  scope :with_document, -> { where.not(document_number: nil) }

  scope :by_state, -> (state) { where(aasm_state: state) }

  scope :by_product_type_keyword, -> (keyword) {
    case keyword
    when "subscription"
      where.not(subscription_refund_from: nil)
    when "basic"
      where(subscription_refund_from: nil)
    when nil
      all
    else
      none
    end
  }

  scope :by_paid_at_range, -> (range_str) {
    from, to = range_str.split(/ ?- ?/)

    runner = self

    if from.present?
      from_date_time = DateTime.parse(from)
      runner = runner.where("paid_at >= ?", from_date_time)
    end

    if to.present?
      to = "#{to} 23:59" if to.exclude?(":")
      to_date_time = DateTime.parse(to)
      runner = runner.where("paid_at <= ?", to_date_time)
    end

    runner
  }

  scope :by_payment_method, -> (method) { where(payment_method: method) }

  pg_search_scope :by_query,
                  against: %i[document_number],
                  associated_against: {
                    order: %i[number email],
                  },
                  ignoring: :accents,
                  using: { tsearch: { prefix: true } }

  validates :order, :issue_date, :due_date, :date_of_taxable_supply, :reason, presence: true
  validates :document_number, uniqueness: true, allow_nil: true
  validates :due_date, comparison: { greater_than_or_equal_to: :issue_date }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validate :subscription_data_validity
  validate :total_price_validity

  aasm do
    state :created, initial: true, color: "yellow"
    state :approved_to_pay, color: "blue"
    state :paid, color: "green"
    state :cancelled, color: "black"

    states = Boutique::Order.aasm.states.map(&:name)

    event :approve do
      transitions from: :created, to: :approved_to_pay
      before do
        self.approved_at = Time.current
        set_document_number
        handle_payout
      end
    end

    event :pay, email_modal: true do
      transitions from: :approved_to_pay, to: :paid
      before do
        self.paid_at = Time.current
      end
    end

    event :cancel do
      transitions from: states.without(:cancelled), to: :cancelled
      before do
        self.cancelled_at = Time.current
      end
    end
  end

  def self.secret_hash_length
    16
  end

  def self.next_number(d_day)
    # self.base_number = ActiveRecord::Base.nextval("boutique_orders_base_number_seq")
    last = Boutique::OrderRefund.where("issue_date > ?", d_day.beginning_of_year)
                                .where.not(document_number: nil)
                                .order(document_number: :asc)
                                .last
    if last
      (last.document_number.to_i + 1).to_s
    else
      year_prefix = d_day.year.to_s.last(2)
      # format: 2200001, 2200002 ... 2309998, 2309999
      year_prefix + "1".rjust(4, "0")
    end
  end

  def aasm_email_default_subject(event)
    case event.name
    when :pay
      I18n.t("boutique.order_refund.events.pay.email_subject", order_number: order.number)
    else
      nil
    end
  end

  def self.payment_method_options
    PAYMENT_METHODS.collect do |method|
      [I18n.t("folio.console.boutique.order_refunds.payment_methods.#{method}"), method]
    end
  end

  def allowed_payment_methods
    original_method = original_payment.normalized_payment_method
    original_method = nil unless PAYMENT_METHODS.include?(original_method)
    [
      original_method,
      "VOUCHER"
    ].compact
  end

  def payment_method_label
    self.class.payment_method_options.detect { |label, key| payment_method == key }&.first
  end

  def to_long_label
    "#{to_label} (#{order.to_label})"
  end

  def to_label
    "#{document_number || "##{id}"}"
  end

  def set_document_number
    self.document_number ||= Boutique::OrderRefund.next_number(issue_date || Date.today)
  end

  def setup_from(order)
    self.boutique_order_id = order.id
    self.issue_date ||= Date.today
    self.due_date ||= Date.today + 14.days
    self.date_of_taxable_supply ||= Date.today
    self.total_price_in_cents = order.total_price_in_cents
    self.payment_method ||= "VOUCHER"
    setup_subscription_refund
  end

  def setup_subscription_refund(date_from = nil, date_to = nil)
    return unless subscription.present?

    date_from = date_from.blank? ? subscription_date_range.begin : [date_from, subscription_date_range.end].min
    date_to = date_to.blank? ? subscription_date_range.end : [date_to, subscription_date_range.begin].max

    if [date_from, date_to] == [subscription_date_range.begin, subscription_date_range.end]
      price_in_cents = order.subscription_line_item.unit_price * 100
    else
      price_in_cents = (date_to.to_date - date_from.to_date) * subscription_price_per_day_in_cents
    end

    self.subscription_refund_from = date_from
    self.subscription_refund_to = date_to
    self.subscriptions_price_in_cents = price_in_cents
    self.total_price_in_cents = price_in_cents
  end

  def subscription_price_per_day_in_cents
    return unless subscription.present?

    @subscription_price_per_day_in_cents ||= order.subscription_line_item.price_per_day * 100
  end

  def subscriptions_price
    subscriptions_price_in_cents.to_f / 100
  end

  def subscriptions_price=(f_value)
    self.subscriptions_price_in_cents = f_value.to_f * 100
  end

  def subscription_date_range
    return nil unless subscription.present?
    @subscription_date_range ||= (order.subscription_line_item.subscription_starts_at.to_date..order.subscription_line_item.subscription_ends_at.to_date)
  end

  def total_price
    total_price_in_cents.to_f / 100
  end

  def total_price=(f_value)
    self.total_price_in_cents = f_value.to_f * 100
  end

  def hide_vat?
    return @hide_vat unless @hide_vat.nil?
    @hide_vat = order.try(:hide_invoice_vat?) == true
  end

  def regular_invoice?
    return @regular_invoice unless @regular_invoice.nil?
    @regular_invoice = order.try(:regular_invoice?) == true
  end

  def corrective_tax_document_title
    if regular_invoice?
      I18n.t("boutique.order_refunds.corrective_tax_document.with_vat_title", number: document_number)
    else
      I18n.t("boutique.order_refunds.corrective_tax_document.no_vat_title", number: document_number)
    end
  end

  LineItemStruct = Struct.new(:to_label, :price, :vat_rate_value, keyword_init: true) do
    def price_vat
      (price * (vat_rate_value.to_d / (100 + vat_rate_value))).round(2).to_f
    end
  end

  def line_items
    if subscription.present?
      o_li = order.subscription_line_item
      from = I18n.l(subscription_refund_from.to_time, format: :as_date)
      to = I18n.l(subscription_refund_to.to_time, format: :as_date)

      [
        LineItemStruct.new(to_label: "#{o_li.title} (#{from} – #{to})",
                           price: subscriptions_price,
                           vat_rate_value: o_li.vat_rate_value)
      ]
    else
      order.line_items.collect do |o_li|
        LineItemStruct.new(to_label: o_li.title,
                           price: o_li.price,
                           vat_rate_value: o_li.vat_rate_value)
      end
    end
  end

  def handle_payout
    case payment_method.to_s
    when "BANK_ACCOUNT", "PAYMENT_CARD"
      if original_payment.present?
        handle_refund_by_payment_gateway
      else
        raise "original_payment is missing for #{self}"
      end
    when "PAYPAL"
      handle_refund_by_paypal
    when "VOUCHER"
      handle_refund_by_voucher
    else
      raise "Unhandled payout for payment_method #{payment_method}"
    end
  end

  private
    def handle_refund_by_payment_gateway
      original_payment.payment_gateway.payout_order_refund(self)
    end

    def handle_refund_by_paypal
      Boutique::OrderRefundMailer.payout_by_paypal(self).deliver_later
    end

    def handle_refund_by_voucher
      Boutique::OrderRefundMailer.payout_by_voucher(self).deliver_later
    end

    def original_payment
      order.payments.paid.last
    end

    def subscription_data_validity
      return unless subscription.present?

      if subscription_refund_from.blank? || subscription_refund_to.blank?
        errors.add(:subscription_refund_from, :blank)
        errors.add(:subscription_refund_to, :blank)
      else
        if subscription_refund_from > subscription_refund_to
          errors.add(:subscription_refund_from, :greater_than, count: subscription_refund_to)
        end

        unless subscription_date_range.include?(subscription_refund_from)
          errors.add(:subscription_refund_from, :inclusion, count: subscription_date_range)
        end

        unless subscription_date_range.include?(subscription_refund_to)
          errors.add(:subscription_refund_to, :inclusion, count:  subscription_date_range)
        end
      end
    end

    def total_price_validity
      if total_price_in_cents.blank?
        errors.add(:total_price, :blank)
      else

        if order.total_price_in_cents < total_price_in_cents
          errors.add(:total_price, :less_than_or_equal_to, count: order.total_price)
        else
          already_refunded = order.refunds.where.not("aasm_state = ? OR id = ?", "cancelled", (id || -1)).sum(:total_price_in_cents)

          if order.total_price_in_cents < (total_price_in_cents + already_refunded)
            errors.add(:total_price, :greater_sum_than_order_price)
          end
        end

        if total_price_in_cents <= 0
          errors.add(:total_price, :greater_than, count: 0)
        end
      end
    end
end

# == Schema Information
#
# Table name: boutique_order_refunds
#
#  id                           :bigint(8)        not null, primary key
#  document_number              :string
#  secret_hash                  :string
#  boutique_order_id            :bigint(8)        not null
#  aasm_state                   :string
#  issue_date                   :date
#  due_date                     :date
#  date_of_taxable_supply       :date
#  reason                       :text
#  subscription_refund_from     :date
#  subscription_refund_to       :date
#  subscriptions_price_in_cents :integer          default(0)
#  total_price_in_cents         :integer          default(0)
#  payment_method               :string
#  paid_at                      :datetime
#  approved_at                  :datetime
#  cancelled_at                 :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
# Indexes
#
#  index_boutique_order_refunds_on_boutique_order_id  (boutique_order_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_order_id => boutique_orders.id)
#
