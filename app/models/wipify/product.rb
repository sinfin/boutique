# frozen_string_literal: true

class Wipify::Product < ApplicationRecord
  has_many :variants, class_name: "Wipify::ProductVariant",
                      foreign_key: :wipify_product_id,
                      dependent: :destroy,
                      inverse_of: :product

  has_one :master_variant, -> { where(master: true) },
                           class_name: "Wipify::ProductVariant",
                           foreign_key: :wipify_product_id

  has_many :variants_without_master, -> { where(master: false) },
                                     class_name: "Wipify::ProductVariant",
                                     foreign_key: :wipify_product_id

  validates :title,
            :master_variant,
            presence: true
end

# == Schema Information
#
# Table name: wipify_products
#
#  id         :bigint(8)        not null, primary key
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
