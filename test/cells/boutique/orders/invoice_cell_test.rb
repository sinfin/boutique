# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::InvoiceCellTest < Cell::TestCase
  test "show" do
    create(:folio_site)
    order = create(:boutique_order, :paid)
    html = cell("boutique/orders/invoice", order).(:show)
    assert html.has_css?(".b-orders-invoice")
  end
end
