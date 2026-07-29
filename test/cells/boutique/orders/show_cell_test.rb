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

  test "the invoice link follows the invoice, not the payment" do
    order = create(:boutique_order, :paid)
    html = cell("boutique/orders/show", order).(:show)

    assert_not_nil order.invoice_number
    assert html.has_link?(href: "/invoice/#{order.secret_hash}")

    order.update_column(:invoice_number, nil)
    html = cell("boutique/orders/show", order).(:show)

    assert_not html.has_link?(href: "/invoice/#{order.secret_hash}")
  end
end
