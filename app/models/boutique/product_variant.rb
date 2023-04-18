# frozen_string_literal: true

class Boutique::ProductVariant < Boutique::ApplicationRecord
  include Folio::Positionable

  belongs_to :product, class_name: "Boutique::Product",
                       foreign_key: :boutique_product_id,
                       inverse_of: :variants,
                       counter_cache: :variants_count

  has_many :subscriptions, class_name: "Boutique::Subscription",
                           foreign_key: :boutique_product_variant_id,
                           inverse_of: :product_variant

  scope :subscriptions, -> {
    joins(:product).where(boutique_products: { type: "Boutique::Product::Subscription" })
  }

  def title
    super || product.title
  end

  def self.pregenerated_thumbnails_base
    h = {
      "Folio::FilePlacement::Cover" => [],
    }

    [
      Boutique::LineItems::SummaryCell::THUMB_SIZE,
      Boutique::Orders::Edit::SummaryCell::THUMB_SIZE,
    ].uniq.each do |size|
      h["Folio::FilePlacement::Cover"] << size
      h["Folio::FilePlacement::Cover"] << size.gsub(/\d+/) { |n| n.to_i * 2 }
    end

    h["Folio::FilePlacement::Cover"] = h["Folio::FilePlacement::Cover"].uniq

    h
  end

  def self.pregenerated_thumbnails
    pregenerated_thumbnails_base
  end

  private
    def positionable_last_record
      product.variants.last if product
    end
end

# == Schema Information
#
# Table name: boutique_product_variants
#
#  id                  :bigint(8)        not null, primary key
#  boutique_product_id :bigint(8)        not null
#  title               :string
#  master              :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  position            :integer
#
# Indexes
#
#  index_boutique_product_variants_on_boutique_product_id  (boutique_product_id)
#  index_boutique_product_variants_on_master               (master) WHERE master
#  index_boutique_product_variants_on_position             (position)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_product_id => boutique_products.id)
#
