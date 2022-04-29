# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::Edit::SummaryCellTest < Cell::TestCase
  test "show" do
    order = create(:boutique_order, line_items_count: 1)
    html = cell("boutique/orders/edit/summary", order).(:show)
    assert html.has_css?(".b-orders-edit-summary")
    assert 1, html.find_all(".b-orders-edit-summary__line-item").size

    order = create(:boutique_order, line_items_count: 2)
    html = cell("boutique/orders/edit/summary", order).(:show)
    assert html.has_css?(".b-orders-edit-summary")
    assert 2, html.find_all(".b-orders-edit-summary__line-item").size
  end
end
