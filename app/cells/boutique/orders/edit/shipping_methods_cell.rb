# frozen_string_literal: true

class Boutique::Orders::Edit::ShippingMethodsCell < Boutique::ApplicationCell
  RADIO_INPUT_ID = "b-orders-edit-shipping-methods-option-input"

  def f
    model
  end

  def shipping_methods
    f.object.allowed_shipping_methods.published.ordered
  end
end
