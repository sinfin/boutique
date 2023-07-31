# frozen_string_literal: true

class Boutique::OrderRefund < Boutique::ApplicationRecord
  include Folio::HasAasmStates

  ALLOWED_PAYMENT_METHODS = %w[
    PAYMENT_CARD
    BANK_ACCOUNT
    APPLE_PAY
    GPAY
    PAYPAL
    VOUCHER
  ]

  belongs_to :order, class_name: "Boutique::Order", foreign_key: :boutique_order_id, inverse_of: :refunds

  delegate :user, :currency_code, :subscription, to: :order

  validates :order, :issue_date, :due_date, :date_of_taxable_supply, presence: true
  validates :document_number, uniqueness: true, allow_nil: true
  validates :due_date, comparison: { greater_than_or_equal_to: :issue_date }
  validates :payment_method, inclusion: { in: ALLOWED_PAYMENT_METHODS }
  validates :total_price, numericality: { less_than: 0 }

  aasm do
    state :created, initial: true, color: "yellow"
    state :approved_to_pay, color: "blue"
    state :paid, color: "green"
    state :cancelled, color: "black"

    event :approve do
      transitions from: :created, to: :approved_to_pay
      before do
        set_document_number
      end
    end

    event :pay do
      transitions from: :approved_to_pay, to: :paid
      before do
        self.paid_at = Time.zone.now
      end
    end

    event :cancel do
      transitions from: %i[created approved_to_pay], to: :cancelled
    end
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

  def self.payment_method_options
    ALLOWED_PAYMENT_METHODS.collect do |method|
      [I18n.t("boutique.order_refunds.payment_methods.#{method}"), method]
    end
  end

  def to_label
    "#{order.to_label} - #{document_number || "##{id}"}"
  end

  def set_document_number
    self.document_number ||= Boutique::OrderRefund.next_number(issue_date || Date.today)
  end

  def setup_subscription_refund(date_from, date_to = nil)
    return unless subscription.present?

    date_to = [date_to, subscription.active_until].compact.min
    price = (date_to.to_date - date_from.to_date) * subscription_price_per_day_in_cents

    self.subscription_refund_from = date_from
    self.subscription_refund_to = date_to
    self.subscriptions_price_in_cents = (-1 * price)
  end

  def subscription_price_per_day_in_cents
    return unless subscription.present?

    order.subscription_line_item.price_per_day * 100
  end

  def subscriptions_price
    subscriptions_price_in_cents.to_f / 100
  end

  def total_price
    total_price_in_cents.to_f / 100
  end

  def total_price=(f_value)
    self.total_price_in_cents = f_value.to_f * 100
  end
end

# == Schema Information
#
# Table name: boutique_order_refunds
#
#  id                     :bigint(8)        not null, primary key
#  number                 :string
#  issue_date             :date
#  due_date               :date
#  date_of_taxable_supply :date
#  boutique_order_id      :bigint(8)        not null
#  reason                 :text
#  total_price_in_cents   :integer
#  aasm_state             :string
#  paid_at                :datetime
#  cancelled_at           :datetime
#  payment_method         :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_boutique_order_refunds_on_boutique_order_id  (boutique_order_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_order_id => boutique_orders.id)
#
