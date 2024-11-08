# frozen_string_literal: true

class Folio::Console::Boutique::Orders::ShippingMethodInputCell < Folio::ConsoleCell
  def f
    model
  end

  def zasilkovna_shipping_methods
    @zasilkovna_shipping_methods ||= f.object.allowed_shipping_methods.select do |sm|
      sm.is_a?(Boutique::ShippingMethod::Zasilkovna::PickupPoint)
    end
  end
end
