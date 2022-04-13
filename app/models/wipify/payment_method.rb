# frozen_string_literal: true


class Wipify::PaymentMethod < ApplicationRecord
  has_many :orders, class_name: "Wipify::Order",
                    foreign_key: :wipify_payment_method_id,
                    dependent: :nullify,
                    inverse_of: :payment_method

  validates :title,
            :price,
            presence: true
end

# == Schema Information
#
# Table name: wipify_payment_methods
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
#  index_wipify_payment_methods_on_position   (position)
#  index_wipify_payment_methods_on_published  (published) WHERE (published = true)
#
