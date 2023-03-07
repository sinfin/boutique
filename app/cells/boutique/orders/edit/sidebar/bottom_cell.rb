# frozen_string_literal: true

class Boutique::Orders::Edit::Sidebar::BottomCell < Boutique::ApplicationCell
  def contents
    # TODO
    model.line_items.first.product_variant.checkout_sidebar_content
  end

  def shipping_info
    @shipping_info ||= model.shipping_info
  end

  def shipping_price
    @shipping_price ||= model.shipping_price
  end

  def shipping_price_summary
    if model.packages_count > 1
      "#{model.packages_count} × #{price(model.shipping_price_per_package)}"
    end
  end
end
