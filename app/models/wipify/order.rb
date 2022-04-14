# frozen_string_literal: true

class Wipify::Order < ApplicationRecord
  include AASM

  belongs_to :customer, polymorphic: true,
                        inverse_of: :order,
                        optional: true

  belongs_to :shipping_method, class_name: "Wipify::ShippingMethod",
                               foreign_key: :wipify_shipping_method_id,
                               inverse_of: :orders,
                               optional: true

  belongs_to :payment_method, class_name: "Wipify::PaymentMethod",
                              foreign_key: :wipify_payment_method_id,
                              inverse_of: :orders,
                              optional: true

  has_many :line_items, -> { ordered },
                        class_name: "Wipify::LineItem",
                        foreign_key: :wipify_order_id,
                        counter_cache: :line_items_count,
                        dependent: :destroy,
                        inverse_of: :order

  validates :email,
            :base_number,
            :number,
            :line_items,
            :payment_method,
            :shipping_method,
            presence: true,
            unless: :pending?

  aasm timestamps: true do
    state :pending, initial: true
    state :confirmed, color: "red"
    state :paid, color: "yellow"
    state :dispatched, color: "green"
    state :cancelled, color: "dark"

    states = Wipify::Order.aasm.states.map(&:name)

    event :confirm do
      transitions from: :pending, to: :confirmed

      before do
        set_numbers
        set_prices
      end

      after_commit do
        Wipify::OrderMailer.confirmed(self).deliver_later
      end
    end

    event :pay do
      transitions from: :confirmed, to: :paid

      after_commit do
        Wipify::OrderMailer.paid(self).deliver_later
      end
    end

    event :dispatch do
      transitions from: :paid, to: :dispatched

      after_commit do
        Wipify::OrderMailer.dispatched(self).deliver_later
      end
    end

    event :cancel do
      transitions from: states.without(:cancelled), to: :cancelled
    end

    event :revert_cancelation do
      transitions from: :cancelled, to: :dispatched, guard: :dispatched_at?
      transitions from: :cancelled, to: :paid, guard: :paid_at?
      transitions from: :cancelled, to: :confirmed, guard: :confirmed_at?
      transitions from: :cancelled, to: :pending

      before { self.cancelled_at = nil }
    end
  end

  def line_items_price
    super || line_items.sum(&:price)
  end

  def shipping_method_price
    super || shipping_method.try(:price)
  end

  def payment_method_price
    super || payment_method.try(:price)
  end

  def total_price
    super || [
      line_items_price,
      shipping_method_price.to_i,
      payment_method_price.to_i,
    ].sum
  end

  private
    def set_numbers
      return if base_number.present?

      year_prefix = Time.zone.now.year.to_s.last(2)
      self.base_number = get_next_base_number

      # format: 2200001, 2200002 ... 2309998, 2309999
      self.number = year_prefix + base_number.to_s.rjust(5, "0")
    end

    def get_next_base_number
      ActiveRecord::Base.nextval("wipify_orders_base_number_seq")
    end

    def set_prices
      self.line_items_price = line_items_price
      self.payment_method_price = payment_method_price.to_i
      self.shipping_method_price = shipping_method_price.to_i
      self.total_price = total_price
    end
end

# == Schema Information
#
# Table name: wipify_orders
#
#  id                        :bigint(8)        not null, primary key
#  customer_type             :string
#  customer_id               :bigint(8)
#  web_session_id            :string
#  base_number               :integer
#  number                    :string
#  email                     :string
#  aasm_state                :string           default("pending")
#  line_items_count          :integer          default(0)
#  line_items_price          :integer
#  shipping_method_price     :integer
#  payment_method_price      :integer
#  total_price               :integer
#  confirmed_at              :datetime
#  paid_at                   :datetime
#  dispatched_at             :datetime
#  cancelled_at              :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  wipify_shipping_method_id :bigint(8)
#  wipify_payment_method_id  :bigint(8)
#
# Indexes
#
#  index_wipify_orders_on_customer                   (customer_type,customer_id)
#  index_wipify_orders_on_number                     (number)
#  index_wipify_orders_on_web_session_id             (web_session_id)
#  index_wipify_orders_on_wipify_payment_method_id   (wipify_payment_method_id)
#  index_wipify_orders_on_wipify_shipping_method_id  (wipify_shipping_method_id)
#
# Foreign Keys
#
#  fk_rails_...  (wipify_payment_method_id => wipify_payment_methods.id)
#  fk_rails_...  (wipify_shipping_method_id => wipify_shipping_methods.id)
#
