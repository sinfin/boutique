# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::Cart::Sidebar::BottomCellTest < Cell::TestCase
  test "show" do
    order = create(:boutique_order, line_items_count: 1)
    html = cell("boutique/orders/cart/sidebar/bottom", order).(:show)
    assert html.has_css?(".b-orders-cart-sidebar-bottom")
  end
end
