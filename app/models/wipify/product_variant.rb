# frozen_string_literal: true

class Wipify::ProductVariant < ApplicationRecord
  belongs_to :product, class_name: "Wipify::Product",
                       foreign_key: :wipify_product_id,
                       inverse_of: :variants

  validates :price,
            presence: true
end

# == Schema Information
#
# Table name: wipify_product_variants
#
#  id                :bigint(8)        not null, primary key
#  wipify_product_id :bigint(8)        not null
#  title             :string
#  price             :integer          not null
#  master            :boolean          default(FALSE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_wipify_product_variants_on_master             (master) WHERE (master = true)
#  index_wipify_product_variants_on_wipify_product_id  (wipify_product_id)
#
# Foreign Keys
#
#  fk_rails_...  (wipify_product_id => wipify_products.id)
#
