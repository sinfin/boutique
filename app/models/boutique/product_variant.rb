# frozen_string_literal: true

class Boutique::ProductVariant < Boutique::ApplicationRecord
  include Folio::HasAttachments
  include Folio::Positionable

  FRIENDLY_ID_SCOPE = :boutique_product_id
  include Folio::FriendlyId

  belongs_to :product, class_name: "Boutique::Product",
                       foreign_key: :boutique_product_id,
                       inverse_of: :variants,
                       counter_cache: :variants_count

  validates :regular_price,
            presence: true

  def current_price
    if discounted?
      discounted_price
    else
      regular_price
    end
  end

  alias :price :current_price

  def discounted?
    return false if discounted_price.nil?

    if discounted_from.present? && discounted_from >= Time.current
      return false
    end

    if discounted_until.present? && discounted_until <= Time.current
      return false
    end

    true
  end

  def self.pregenerated_thumbnails
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

  private
    def positionable_last_record
      product.variants.last if product
    end
end

# == Schema Information
#
# Table name: boutique_product_variants
#
#  id                       :bigint(8)        not null, primary key
#  boutique_product_id      :bigint(8)        not null
#  title                    :string
#  checkout_sidebar_content :text
#  regular_price            :integer          not null
#  discounted_price         :integer
#  discounted_from          :datetime
#  discounted_until         :datetime
#  master                   :boolean          default(FALSE)
#  digital_only             :boolean          default(FALSE)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  position                 :integer
#  slug                     :string
#  description              :text
#
# Indexes
#
#  index_boutique_product_variants_on_boutique_product_id  (boutique_product_id)
#  index_boutique_product_variants_on_master               (master) WHERE master
#  index_boutique_product_variants_on_position             (position)
#  index_boutique_product_variants_on_slug                 (slug)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_product_id => boutique_products.id)
#
