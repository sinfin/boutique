# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::Edit::Sidebar::BottomCellTest < Cell::TestCase
  test "show" do
    order = create(:boutique_order, line_items_count: 1)
    html = cell("boutique/orders/edit/sidebar/bottom", order).(:show)
    assert html.has_css?(".b-orders-edit-sidebar-bottom")
  end
end
