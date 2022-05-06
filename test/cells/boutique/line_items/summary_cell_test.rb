# frozen_string_literal: true

require "test_helper"

class Boutique::LineItems::SummaryCellTest < Cell::TestCase
  test "show" do
    order = create(:boutique_order, line_items_count: 1)
    html = cell("boutique/line_items/summary", order.line_items).(:show)
    assert html.has_css?(".b-line-items-summary")
  end
end
