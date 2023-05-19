# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::CartCellTest < Cell::TestCase
  test "show" do
    current_order = create(:boutique_order, line_items_count: 1)
    html = cell("boutique/orders/cart", nil, current_order:).(:show)
    assert html.has_css?(".b-orders-cart")
  end
end
