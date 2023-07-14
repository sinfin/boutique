# frozen_string_literal: true

class Boutique::ShippingMethod::Zasilkovna::HomeDelivery < Boutique::ShippingMethod::Zasilkovna::Default
  def requires_address?
    true
  end

  def requires_pickup_point?
    false
  end

  def register(order)
    Boutique::Carrier::Zasilkovna.new.register!(order, home_delivery: true)
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
