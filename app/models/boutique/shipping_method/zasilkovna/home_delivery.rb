# frozen_string_literal: true

class Boutique::ShippingMethod::Zasilkovna::HomeDelivery < Boutique::ShippingMethod::Zasilkovna::PickupPoint
  def requires_address?
    true
  end

  def requires_pickup_point?
    false
  end

  def register!(order)
    carrier.register!(order, home_delivery: true)
  end

  def get_labels(orders, format: :pdf)
    case format.to_sym
    when :pdf
      carrier.get_courier_pdf_label(order)
    else
      "unsupported label format!"
    end
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
