# frozen_string_literal: true

class Boutique::Orders::Cart::Sidebar::BottomCell < Boutique::ApplicationCell
  def shipping_info
    @shipping_info ||= model.shipping_info
  end

  def shipping_price
    @shipping_price ||= model.shipping_price
  end

  def shipping_price_summary
    @shipping_price_summary ||= if model.packages_count > 1
      "#{model.packages_count} × #{price(model.shipping_price_per_package)}"
    end
  end
end
