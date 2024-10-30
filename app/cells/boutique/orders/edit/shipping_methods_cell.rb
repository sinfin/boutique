# frozen_string_literal: true

class Boutique::Orders::Edit::ShippingMethodsCell < Boutique::ApplicationCell
  RADIO_INPUT_ID = "b-orders-edit-shipping-methods-option-input"

  def f
    model
  end

  def shipping_methods
    Boutique::ShippingMethod.published.ordered
  end
end
