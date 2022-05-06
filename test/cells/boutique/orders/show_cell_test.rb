# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::ShowCellTest < Cell::TestCase
  test "show" do
    order = create(:boutique_order, :confirmed)
    html = cell("boutique/orders/show", order).(:show)
    assert html.has_css?(".b-orders-show")

    order.pay!
    html = cell("boutique/orders/show", order).(:show)
    assert html.has_css?(".b-orders-show")
  end
end
