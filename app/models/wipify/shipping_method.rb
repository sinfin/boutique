# frozen_string_literal: true


class Wipify::ShippingMethod < ApplicationRecord
  has_many :orders, class_name: "Wipify::Order",
                    foreign_key: :wipify_shipping_method_id,
                    dependent: :nullify,
                    inverse_of: :shipping_method

  validates :title,
          :price,
          presence: true
end
