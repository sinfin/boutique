# frozen_string_literal: true

class Wipify::Order < ApplicationRecord
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
end
