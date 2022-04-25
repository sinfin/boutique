# frozen_string_literal: true

class Boutique::ProductVariant < Boutique::ApplicationRecord
  belongs_to :product, class_name: "Boutique::Product",
                       foreign_key: :boutique_product_id,
                       inverse_of: :variants

  validates :price,
            presence: true
end

# == Schema Information
#
# Table name: boutique_product_variants
#
#  id                  :bigint(8)        not null, primary key
#  boutique_product_id :bigint(8)        not null
#  title               :string
#  price               :integer          not null
#  master              :boolean          default(FALSE)
#  digital_only        :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_boutique_product_variants_on_boutique_product_id  (boutique_product_id)
#  index_boutique_product_variants_on_master               (master) WHERE master
#
# Foreign Keys
#
#  fk_rails_...  (boutique_product_id => boutique_products.id)
#
