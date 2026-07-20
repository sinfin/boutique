# frozen_string_literal: true

class Boutique::ShippingMethod::Zasilkovna::PickupPoint < Boutique::ShippingMethod
  def requires_address?
    false
  end

  def requires_pickup_point?
    true
  end

  def register!(order)
    carrier.register!(order)
  end

  def tracking_url_for(order)
    "https://tracking.packeta.com/cs_CZ/?id=#{order.package_tracking_id}"
  end

  def get_label(order, format: :pdf)
    case format.to_sym
    when :pdf
      carrier.get_pdf_label(order)
    else
      "unsupported label format!"
    end
  end

  private
    def carrier
      @carrier ||= Boutique::Carrier::Zasilkovna.new
    end
end
