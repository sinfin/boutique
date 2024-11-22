# frozen_string_literal: true

class Boutique::Product < Boutique::ApplicationRecord
  extend Folio::InheritenceBaseNaming

  include Folio::HasAttachments
  include Folio::FriendlyId
  include Folio::Publishable::WithDate
  include Folio::RecursiveSubclasses
  include Folio::StiPreload

  belongs_to :site, class_name: "Folio::Site",
                    required: Boutique.config.products_belong_to_site

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

  has_many :subscriptions, through: :variants

  has_and_belongs_to_many :shipping_methods, class_name: "Boutique::ShippingMethod"

  validates :code,
            :title,
            :type,
            :regular_price,
            presence: true

  validates :regular_price,
            :discounted_price,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :code,
            length: { maximum: 32 },
            uniqueness: true,
            allow_nil: true

  validates :site, inclusion: { in: proc { sites_for_select } },
                   allow_nil: true

  validate :validate_master_variant_presence

  pg_search_scope :by_query,
                against: %i[title],
                ignoring: :accents,
                using: {
                  tsearch: { prefix: true }
                }

  after_initialize :set_default_vat_rate
  after_initialize :set_default_shipping_methods

  def subscription?
    is_a?(Boutique::Product::Subscription)
  end

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

  def discount
    return unless discounted?

    regular_price - discounted_price
  end

  def discount_in_percentages
    return unless discounted?

    (100 * (discount / regular_price.to_f)).round(2)
  end

  def free?
    current_price.zero?
  end

  def age_restricted?
    false
  end

  def max_purchase_amount_allowed
    # override in main app if needed, use nil for unlimited
    1
  end

  def self.default_shipping_methods
    []
  end

  def self.sites_for_select
    Folio::Site.ordered
  end

  def self.additional_params
    []
  end

  def self.additional_columns_for_console_index_table
    []
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

  def self.sti_paths
    [
      Boutique::Engine.root.join("app/models/boutique/product"),
    ]
  end

  def to_line_item_full_label(html_context: nil, product_variant: nil, subscription_starts_at: nil, order: nil)
    if product_variant
      product_variant.to_line_item_full_label(html_context:, product_for_label: self, subscription_starts_at:)
    else
      title
    end
  end

  private
    def set_default_vat_rate
      self.vat_rate = Boutique::VatRate.default if self.boutique_vat_rate_id.nil?
    end

    def set_default_shipping_methods
      return unless new_record?

      self.shipping_methods = self.class.default_shipping_methods
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
#  id                                      :bigint(8)        not null, primary key
#  title                                   :string           not null
#  slug                                    :string           not null
#  published                               :boolean          default(FALSE)
#  published_at                            :datetime
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  type                                    :string
#  variants_count                          :integer          default(0)
#  subscription_frequency                  :string
#  boutique_vat_rate_id                    :bigint(8)        not null
#  site_id                                 :bigint(8)
#  shipping_info                           :text
#  digital_only                            :boolean          default(FALSE)
#  subscription_recurrent_payment_disabled :boolean          default(FALSE)
#  preview_token                           :string
#  code                                    :string(32)
#  checkout_sidebar_content                :text
#  description                             :text
#  subscription_period                     :integer          default(12)
#  regular_price                           :integer
#  discounted_price                        :integer
#  discounted_from                         :datetime
#  discounted_until                        :datetime
#  best_offer                              :boolean          default(FALSE)
#  variant_type_title                      :string
#
# Indexes
#
#  index_boutique_products_on_boutique_vat_rate_id  (boutique_vat_rate_id)
#  index_boutique_products_on_published             (published)
#  index_boutique_products_on_published_at          (published_at)
#  index_boutique_products_on_site_id               (site_id)
#  index_boutique_products_on_slug                  (slug)
#  index_boutique_products_on_type                  (type)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_vat_rate_id => boutique_vat_rates.id)
#
