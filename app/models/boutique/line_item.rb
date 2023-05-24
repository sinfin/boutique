# frozen_string_literal: true

class Boutique::LineItem < Boutique::ApplicationRecord
  belongs_to :order, class_name: "Boutique::Order",
                     foreign_key: :boutique_order_id,
                     inverse_of: :line_items,
                     counter_cache: :line_items_count

  belongs_to :product_variant, class_name: "Boutique::ProductVariant",
                               foreign_key: :boutique_product_variant_id

  scope :ordered, -> { order(id: :desc) }

  validates :amount,
            numericality: { greater_than_or_equal_to: 1 }

  delegate :product,
           to: :product_variant
  delegate :digital_only?,
           :subscription?,
           to: :product

  after_initialize :set_default_subscription_recurring
  before_validation :unset_unwanted_subscription_starts_at

  def to_label
    product_variant.title
  end

  def cover_placement_from_variant_or_product
    product_variant.cover_placement || product_variant.product.cover_placement
  end

  def summary_title
    product.title
  end

  def summary_subtitle
    product_variant.title
  end

  def summary_cover_placement
    cover_placement_from_variant_or_product
  end

  def to_full_label
    return to_label unless subscription_starts_at && subscription_period

    from = I18n.l(subscription_starts_at, format: :as_date)
    to = I18n.l(subscription_starts_at + subscription_period.months, format: :as_date)

    "#{to_label} (#{from} – #{to})"
  end

  def to_console_label
    to_full_label
  end

  def invoice_title
    to_full_label
  end

  def price
    (subscription_period || 1) * amount * unit_price
  end

  def price_vat
    (subscription_period || 1) * amount * unit_price_vat
  end

  def price_without_vat
    price - price_vat
  end

  def unit_price
    super || product_variant.price
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

  def subscription_starts_at
    super || order.gift_recipient_notification_scheduled_for || order.confirmed_at
  end

  def imprint
    self.unit_price = unit_price
    self.vat_rate_value = vat_rate_value

    if subscription?
      self.subscription_starts_at = subscription_starts_at
      self.subscription_period = product_variant.subscription_period if subscription_recurring?
    end

    self
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

    def set_default_subscription_recurring
      self.subscription_recurring ||= false
    end

    def unset_unwanted_subscription_starts_at
      return unless order.pending?
      return if requires_subscription_starts_at?

      self.subscription_starts_at = nil
    end
end

# == Schema Information
#
# Table name: boutique_line_items
#
#  id                          :bigint(8)        not null, primary key
#  boutique_order_id           :bigint(8)        not null
#  amount                      :integer          default(1)
#  unit_price                  :integer
#  subscription_starts_at      :datetime
#  subscription_recurring      :boolean
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  boutique_product_variant_id :bigint(8)        not null
#  vat_rate_value              :integer
#  subscription_period         :integer
#
# Indexes
#
#  index_boutique_line_items_on_boutique_order_id            (boutique_order_id)
#  index_boutique_line_items_on_boutique_product_variant_id  (boutique_product_variant_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_order_id => boutique_orders.id)
#  fk_rails_...  (boutique_product_variant_id => boutique_product_variants.id)
#
