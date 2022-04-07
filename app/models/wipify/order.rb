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

  has_many :line_items, class_name: "Wipify::LineItem",
                        foreign_key: :wipify_order_id,
                        dependent: :destroy,
                        inverse_of: :order

  aasm timestamps: true do
    state :pending, initial: true
    state :confirmed, color: "red"
    state :paid, color: "yellow"
    state :dispatched, color: "green"
    state :cancelled, color: "dark"

    states = Wipify::Order.aasm.states.map(&:name)

    event :confirm do
      transitions from: :pending, to: :confirmed
    end

    event :pay do
      transitions from: :confirmed, to: :paid
    end

    event :dispatch do
      transitions from: :paid, to: :dispatched
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
end
