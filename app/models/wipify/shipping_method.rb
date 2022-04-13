# frozen_string_literal: true


class Wipify::ShippingMethod < ApplicationRecord
  has_many :orders, class_name: "Wipify::Order",
                    foreign_key: :wipify_shipping_method_id,
                    dependent: :nullify,
                    inverse_of: :shipping_method

  validates :title,
            :price,
            presence: true
end

# == Schema Information
#
# Table name: wipify_shipping_methods
#
#  id          :bigint(8)        not null, primary key
#  title       :string
#  type        :string
#  description :text
#  price       :string
#  position    :integer
#  published   :boolean          default(FALSE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_wipify_shipping_methods_on_position   (position)
#  index_wipify_shipping_methods_on_published  (published) WHERE (published = true)
#
