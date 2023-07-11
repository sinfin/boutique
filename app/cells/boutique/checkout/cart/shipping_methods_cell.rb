# frozen_string_literal: true

class Boutique::Checkout::Cart::ShippingMethodsCell < ApplicationCell
  def shipping_method_input
    model.association :shipping_method, as: :radio_buttons,
                                        collection: shipping_method_options,
                                        input_html: { class: "b-checkout-cart-shipping-methods__item-input" },
                                        item_wrapper_class: "form-check b-checkout-cart-shipping-methods__item",
                                        item_label_class: "b-checkout-cart-shipping-methods__item-label",
                                        legend_tag: false
  end

  def shipping_method_options
    shipping_methods = Boutique::ShippingMethod.published
                                               .ordered

    shipping_methods.map do |sm|
      label = [
        sm.title,
        content_tag(:div, price(sm.price), class: "b-checkout-cart-shipping-methods__item-label-price")
      ].join.html_safe

      [label, sm.id]
    end
  end
end
