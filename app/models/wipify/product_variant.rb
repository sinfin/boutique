# frozen_string_literal: true

class Wipify::ProductVariant < ApplicationRecord
  belongs_to :product, class_name: "Wipify::Product",
                       foreign_key: :wipify_product_id,
                       inverse_of: :product_variants

  validates :price,
            presence: true
end
