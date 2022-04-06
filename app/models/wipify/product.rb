# frozen_string_literal: true

class Wipify::Product < ApplicationRecord
  has_many :product_variants, class_name: "Wipify::ProductVariant",
                              foreign_key: :wipify_product_id,
                              dependent: :destroy,
                              inverse_of: :product
end
