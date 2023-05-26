# frozen_string_literal: true

class Boutique::LineItem < Boutique::ApplicationRecord
  belongs_to :order, class_name: "Boutique::Order",
                     foreign_key: :boutique_order_id,
                     inverse_of: :line_items,
                     counter_cache: :line_items_count

  belongs_to :product, class_name: "Boutique::Product"

  belongs_to :product_variant, class_name: "Boutique::ProductVariant",
                               optional: true

  scope :ordered, -> { order(id: :desc) }

  validates :amount,
            numericality: { greater_than_or_equal_to: 1 }

  validate :validate_product_variant

  delegate :cover,
           :cover_placement,
           :digital_only?,
           :subscription?,
           to: :product

  before_validation :unset_unwanted_subscription_starts_at

  def to_label
    [
      product.title,
      product_variant.try(:title)
    ].compact.join(" / ")
  end

  def to_full_label(html_context: nil, order_for_label: nil)
    product.to_line_item_full_label(html_context:, product_variant:, subscription_starts_at:, order: order_for_label || order)
  end

  def to_console_label
    to_full_label
  end

  def price
    amount * unit_price
  end

  def price_vat
    amount * unit_price_vat
  end

  def price_without_vat
    price - price_vat
  end

  def unit_price
    super || product.price
  end

  def vat_rate_value
    super || product.vat_rate.value
  end

  def unit_price_vat
    (unit_price * (vat_rate_value.to_d / (100 + vat_rate_value))).round(2).to_f
  end

  def unit_price_without_vat
    (unit_price - unit_price_vat.to_d).to_f
  end

  def subscription_period
    super || product.subscription_period
  end

  def imprint
    self.product_variant ||= product.master_variant

    self.unit_price = unit_price
    self.vat_rate_value = vat_rate_value
    self.subscription_period = subscription_period
  end

  def summary_text
    to_label
  end

  def requires_subscription_starts_at?
    product.subscription? && product.has_subscription_frequency?
  end

  def requires_subscription_recurring?
    product.subscription? && !product.subscription_recurrent_payment_disabled?
  end

  def subscription_starts_at_options_for_select
    product.current_and_upcoming_issues.map do |issue|
      date = Date.new(issue[:year], issue[:month])
      [subscription_starts_at_label(date, issue[:number]), date]
    end
  end

  private
    def subscription_starts_at_label(date, number)
      "#{I18n.t('boutique.issue').capitalize} #{number} / #{date.year}"
    end

    def unset_unwanted_subscription_starts_at
      return unless order.pending?
      return if requires_subscription_starts_at?

      self.subscription_starts_at = nil
    end

    def validate_product_variant
      return if order.pending? || product_variant.present?

      if product.variants.size > 1
        errors.add(:product_variant, :blank)
      end
    end
end

# == Schema Information
#
# Table name: boutique_line_items
#
#  id                     :bigint(8)        not null, primary key
#  boutique_order_id      :bigint(8)        not null
#  amount                 :integer          default(1)
#  unit_price             :integer
#  subscription_starts_at :datetime
#  subscription_recurring :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  product_variant_id     :bigint(8)
#  vat_rate_value         :integer
#  subscription_period    :integer
#  product_id             :bigint(8)
#
# Indexes
#
#  index_boutique_line_items_on_boutique_order_id   (boutique_order_id)
#  index_boutique_line_items_on_product_id          (product_id)
#  index_boutique_line_items_on_product_variant_id  (product_variant_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_order_id => boutique_orders.id)
#  fk_rails_...  (product_id => boutique_products.id)
#  fk_rails_...  (product_variant_id => boutique_product_variants.id)
#
