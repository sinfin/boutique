# frozen_string_literal: true

class Boutique::Orders::Edit::ShippingMethods::LabelCell < Boutique::ApplicationCell
  def label_for(shipping_method)
    [
      shipping_method.to_label,
      "(#{price(shipping_method.price_for(f.object.primary_address&.country_code))})"
    ].join(" ")
  end
end
