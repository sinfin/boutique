# frozen_string_literal: true

class Boutique::ShippingMethods::Zasilkovna::PickupPointCell < Boutique::ApplicationCell
  def error?
    model.object.errors[:pickup_point_id].present?
  end
end
