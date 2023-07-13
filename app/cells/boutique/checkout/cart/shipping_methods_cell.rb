# frozen_string_literal: true

class Boutique::Checkout::Cart::ShippingMethodsCell < ApplicationCell
  def f
    model
  end

  def shipping_methods
    Boutique::ShippingMethod.published.ordered
  end
end
