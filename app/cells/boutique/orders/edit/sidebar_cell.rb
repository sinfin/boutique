# frozen_string_literal: true

class Boutique::Orders::Edit::SidebarCell < Boutique::ApplicationCell
  def contents
    # TODO
    product_variant.checkout_sidebar_content
  end

  def product_variant
    @product_variant ||= model.line_items.first.product_variant
  end

  def shipping_info
    @shipping_info ||= product_variant.product.shipping_info
  end
end
