# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::Orders::ShowForModelCellTest < Folio::Console::CellTest
  test "show" do
    order = create(:boutique_order, :paid)
    html = cell("folio/console/boutique/orders/show_for_model", order).(:show)
    assert html.has_css?(".f-c-b-orders-show-for-model")
  end
end
