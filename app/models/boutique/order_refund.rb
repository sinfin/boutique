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

  belongs_to :boutique_order, class_name: "Boutique::Order", foreign_key: :boutique_order_id, inverse_of: :refunds

  delegate :user, :currency_code, to: :order

  aasm do
    state :created, initial: true, color: "yellow"
    state :approved_to_pay, color: "blue"
    state :paid, color: "green"
    state :cancelled, color: "black"

    event :approve do
      transitions from: :created, to: :approved_to_pay
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
    #self.base_number = ActiveRecord::Base.nextval("boutique_orders_base_number_seq")
    last = Boutique::OrderRefund.where("issue_date > ?", d_day.beginning_of_year).order(:issue_date).last
    if last
      last.number.to_i +1
    else
      year_prefix = d_day.year.to_s.last(2)
      # format: 2200001, 2200002 ... 2309998, 2309999
      year_prefix + "1".rjust(5, "0")
    end
  end

  def self.payment_method_options
    ALLOWED_PAYMENT_METHODS.collect do |method|
      [I18n.t("boutique.order_refunds.payment_methods.#{method}"), method]
    end
  end

  def number_prefix
    nil
  end

  def initialize(*args)
    super(*args)
    self.issue_date ||= Date.today
    self.number ||= Boutique::OrderRefund.next_number(issue_date || Date.today)
    self.due_date ||= Date.today + 14.days
    self.date_of_taxable_supply ||= Date.today
    self.total_price_in_cents ||= 0
    self.aasm_state ||= "created"
    self.payment_method ||= "VOUCHER"
  end


  def total_price
    total_price_in_cents.to_f / 100
  end

  def total_price=(f_value)
    total_price_in_cents = f_value.to_f * 100
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
