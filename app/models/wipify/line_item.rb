# frozen_string_literal: true

class Wipify::LineItem < ApplicationRecord
  belongs_to :order, class_name: "Wipify::Order",
                     foreign_key: :wipify_order_id,
                     inverse_of: :line_items,
                     counter_cache: :line_items_count
end
