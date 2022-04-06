# frozen_string_literal: true

class Wipify::Order < ApplicationRecord
  belongs_to :customer, polymorphic: true

  has_many :line_items, class_name: "Wipify::LineItem",
                        foreign_key: :wipify_order_id,
                        dependent: :destroy,
                        inverse_of: :order
end
