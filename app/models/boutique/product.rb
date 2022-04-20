# frozen_string_literal: true

class Boutique::Product < Boutique::ApplicationRecord
  include Folio::FriendlyId
  include Folio::Publishable::WithDate

  has_many :variants, class_name: "Boutique::ProductVariant",
                      foreign_key: :boutique_product_id,
                      dependent: :destroy,
                      inverse_of: :product

  has_one :master_variant, -> { where(master: true) },
                           class_name: "Boutique::ProductVariant",
                           foreign_key: :boutique_product_id

  has_many :variants_without_master, -> { where(master: false) },
                                     class_name: "Boutique::ProductVariant",
                                     foreign_key: :boutique_product_id

  validates :title,
            :master_variant,
            presence: true
end

# == Schema Information
#
# Table name: boutique_products
#
#  id           :bigint(8)        not null, primary key
#  title        :string           not null
#  slug         :string           not null
#  published    :boolean          default(FALSE)
#  published_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_boutique_products_on_published     (published)
#  index_boutique_products_on_published_at  (published_at)
#  index_boutique_products_on_slug          (slug)
#
