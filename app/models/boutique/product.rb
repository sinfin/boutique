# frozen_string_literal: true

class Boutique::Product < Boutique::ApplicationRecord
  extend Folio::InheritenceBaseNaming

  include Folio::HasAttachments
  include Folio::FriendlyId
  include Folio::Publishable::WithDate
  include Folio::RecursiveSubclasses
  include Folio::StiPreload

  belongs_to :vat_rate, class_name: "Boutique::VatRate",
                       foreign_key: :boutique_vat_rate_id,
                       inverse_of: :products

  has_many :variants, -> { ordered },
                      class_name: "Boutique::ProductVariant",
                      foreign_key: :boutique_product_id,
                      dependent: :destroy,
                      inverse_of: :product

  accepts_nested_attributes_for :variants, reject_if: :all_blank, allow_destroy: true

  has_one :master_variant, -> { where(master: true) },
                           class_name: "Boutique::ProductVariant",
                           foreign_key: :boutique_product_id

  has_many :variants_without_master, -> { where(master: false) },
                                     class_name: "Boutique::ProductVariant",
                                     foreign_key: :boutique_product_id

  validates :title,
            :type,
            presence: true

  validate :validate_master_variant_presence

  after_initialize :set_default_vat_rate

  def subscription?
    is_a?(Boutique::Product::Subscription)
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

  def self.sti_paths
    [
      Boutique::Engine.root.join("app/models/boutique/product"),
    ]
  end

  private
    def set_default_vat_rate
      self.vat_rate ||= Boutique::VatRate.default
    end

    def validate_master_variant_presence
      master_ary = []

      variants.each do |variant|
        if !variant.marked_for_destruction? && variant.master?
          master_ary << variant
        end
      end

      case master_ary.size
      when 0
        errors.add(:base, :missing_master_variant)
      when 1
        # all good
      else
        errors.add(:base, :too_many_master_variants)
      end
    end
end

# == Schema Information
#
# Table name: boutique_products
#
#  id                     :bigint(8)        not null, primary key
#  title                  :string           not null
#  slug                   :string           not null
#  published              :boolean          default(FALSE)
#  published_at           :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  type                   :string
#  variants_count         :integer          default(0)
#  subscription_frequency :string
#  boutique_vat_rate_id   :bigint(8)        not null
#
# Indexes
#
#  index_boutique_products_on_boutique_vat_rate_id  (boutique_vat_rate_id)
#  index_boutique_products_on_published             (published)
#  index_boutique_products_on_published_at          (published_at)
#  index_boutique_products_on_slug                  (slug)
#  index_boutique_products_on_type                  (type)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_vat_rate_id => boutique_vat_rates.id)
#
