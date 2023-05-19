# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::SummaryCellTest < Cell::TestCase
  test "show" do
    order = create(:boutique_order, :ready_to_be_confirmed)
    html = cell("boutique/orders/summary", order).(:show)
    assert html.has_css?(".b-orders-summary")
    assert html.has_css?(".b-orders-summary__form")

    order = create(:boutique_order, :paid)
    html = cell("boutique/orders/summary", order).(:show)
    assert html.has_css?(".b-orders-summary")
    assert_not html.has_css?(".b-orders-summary__form")
  end
end
