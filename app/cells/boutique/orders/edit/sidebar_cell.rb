# frozen_string_literal: true

class Boutique::Orders::Edit::SidebarCell < Boutique::ApplicationCell
  def contents
    # TODO
    model.line_items.first.product_variant.checkout_sidebar_content
  end
end
