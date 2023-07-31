# frozen_string_literal: true

class Boutique::Checkout::Cart::ShippingMethodsCell < ApplicationCell
  RADIO_INPUT_ID = "b-checkout-cart-shipping-methods-option-input"

  def f
    model
  end

  def shipping_methods
    Boutique::ShippingMethod.published.ordered
  end
end
