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

  delegate :cover,
           :cover_placement,
           to: :product

  def to_label
    product_variant.title
  end

  def price
    amount * unit_price
  end

  def unit_price
    super || product_variant.price
  end

  def imprint_unit_price!
    update!(unit_price:)
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
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  boutique_product_variant_id :bigint(8)        not null
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
