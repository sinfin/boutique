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
