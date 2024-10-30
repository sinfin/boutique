# frozen_string_literal: true

class Boutique::ShippingMethod::Zasilkovna::PickupPoint < Boutique::ShippingMethod
  def requires_address?
    false
  end

  def requires_pickup_point?
    true
  end

  def tracking_url_for(order)
    # "https://tracking.packeta.com/cs_CZ/?id=#{order.package_tracking_id}"
  end
end

# == Schema Information
#
# Table name: boutique_shipping_methods
#
#  id           :bigint(8)        not null, primary key
#  title        :string
#  price        :integer
#  type         :string
#  country_code :string
#  published    :boolean          default(FALSE)
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_boutique_shipping_methods_on_position   (position)
#  index_boutique_shipping_methods_on_published  (published)
#
