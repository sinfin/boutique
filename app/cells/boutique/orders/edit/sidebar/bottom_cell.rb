# frozen_string_literal: true

class Boutique::Orders::Edit::Sidebar::BottomCell < Boutique::ApplicationCell
  def shipping_info
    @shipping_info ||= [
      model.shipping_info,
      model.shipping_method.try(:description)
    ].compact_blank.join
  end

  def shipping_price
    @shipping_price ||= model.shipping_price
  end
end
