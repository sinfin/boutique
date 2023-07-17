# frozen_string_literal: true

class Boutique::ShippingMethod < ApplicationRecord
  extend Folio::InheritenceBaseNaming

  include Folio::Publishable::Basic
  include Folio::Positionable
  include Folio::RecursiveSubclasses

  has_one :order, class_name: "Boutique::Order",
                  inverse_of: :shipping_method

  validates :title,
            :price,
            presence: true

  validates :price,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  def self.use_preview_tokens?
    false
  end

  def requires_address?
    true
  end

  def requires_pickup_point?
    false
  end

  def register(order)
    nil
  end

  def tracking_url_for(order)
    nil
  end

  def get_labels(orders, format: :pdf)
    nil
  end
end

# == Schema Information
#
# Table name: boutique_shipping_methods
#
#  id         :bigint(8)        not null, primary key
#  title      :string
#  price      :integer
#  type       :string
#  published  :boolean          default(FALSE)
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_boutique_shipping_methods_on_position   (position)
#  index_boutique_shipping_methods_on_published  (published)
#
