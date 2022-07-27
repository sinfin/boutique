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

  delegate :digital_only?,
           :product,
           to: :product_variant

  def to_label
    product_variant.title
  end

  def to_full_label
    to_label
  end

  def subscription?
    product.is_a?(Boutique::Product::Subscription)
  end

  def price
    amount * unit_price
  end

  def unit_price
    super || product_variant.price
  end

  def vat_rate_value
    super || product.vat_rate.value
  end

  def price_vat
    (price * (vat_rate_value.to_f / (100 + vat_rate_value))).round(2)
  end

  def price_without_vat
    price - price_vat
  end

  def imprint!
    update!(unit_price:,
            vat_rate_value:)
  end

  def cover_placement_from_variant_or_product
    product_variant.cover_placement || product_variant.product.cover_placement
  end

  def summary_text
    to_label
  end

  def subscription_starts_at_options_for_select
    product.current_and_upcoming_issues.map do |issue|
      date = Date.new(issue[:year], issue[:month])
      overlap_in_months = product.subscription_frequency_in_months_per_issue - 1

      [subscription_starts_at_label(date, issue[:number], overlap_in_months), date]
    end
  end

  private
    def subscription_starts_at_label(date, number, overlap_in_months)
      from = I18n.l(date, format: "%B")
      if overlap_in_months > 0
        to = I18n.l(date + overlap_in_months.months, format: "%B")
      end

      title = [from, to].compact.join(" / ")
      year = date.year.to_s.last(2)

      "#{number}/#{year} – #{title}"
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
