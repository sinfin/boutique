# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::Orders::PaymentInfoCellTest < Folio::Console::CellTest
  test "show" do
    model = create(:boutique_order)
    html = cell("folio/console/boutique/orders/payment_info", model).(:show)
    assert html.has_css?(".f-c-b-orders-payment-info")
  end
end
