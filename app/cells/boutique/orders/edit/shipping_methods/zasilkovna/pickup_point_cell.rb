# frozen_string_literal: true

class Boutique::Orders::Edit::ShippingMethods::Zasilkovna::PickupPointCell < Boutique::ApplicationCell
  def error?
    model.object.errors[:pickup_point_remote_id].present?
  end
end
