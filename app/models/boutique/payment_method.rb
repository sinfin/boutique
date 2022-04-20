# frozen_string_literal: true

class Boutique::PaymentMethod < Boutique::ApplicationRecord
  has_many :orders, class_name: "Boutique::Order",
                    foreign_key: :boutique_payment_method_id,
                    dependent: :nullify,
                    inverse_of: :payment_method

  validates :title,
            :price,
            presence: true
end

# == Schema Information
#
# Table name: boutique_payment_methods
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
#  index_boutique_payment_methods_on_position   (position)
#  index_boutique_payment_methods_on_published  (published)
#
