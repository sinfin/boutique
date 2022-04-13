# frozen_string_literal: true

class Wipify::LineItem < ApplicationRecord
  belongs_to :order, class_name: "Wipify::Order",
                     foreign_key: :wipify_order_id,
                     inverse_of: :line_items,
                     counter_cache: :line_items_count

  belongs_to :product_variant, class_name: "Wipify::ProductVariant",
                               foreign_key: :wipify_product_variant_id

  scope :ordered, -> { order(id: :desc) }

  def price
    super || product_variant.price
  end
end

# == Schema Information
#
# Table name: wipify_line_items
#
#  id                        :bigint(8)        not null, primary key
#  wipify_order_id           :bigint(8)        not null
#  price                     :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  wipify_product_variant_id :bigint(8)        not null
#
# Indexes
#
#  index_wipify_line_items_on_wipify_order_id            (wipify_order_id)
#  index_wipify_line_items_on_wipify_product_variant_id  (wipify_product_variant_id)
#
# Foreign Keys
#
#  fk_rails_...  (wipify_order_id => wipify_orders.id)
#  fk_rails_...  (wipify_product_variant_id => wipify_product_variants.id)
#
