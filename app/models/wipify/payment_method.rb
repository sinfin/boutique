# frozen_string_literal: true


class Wipify::PaymentMethod < ApplicationRecord
  has_many :orders, class_name: "Wipify::Order",
                    foreign_key: :wipify_payment_method_id,
                    dependent: :nullify,
                    inverse_of: :payment_method
end
