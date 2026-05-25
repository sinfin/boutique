# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::Orders::CatalogueCellTest < Folio::Console::CellTest
  # Cell rendering goes through Folio::Console::BaseController#current_ability
  # → Devise's current_account → Warden, which is not available in cell tests.
  # Patch the permission check directly so rows render via show_link.
  # Done via Module#prepend (survives across tests) rather than Mocha any_instance
  # stubs which would only apply per-test.
  module StubPermissions
    def can?(*); true; end
  end
  Folio::Console::BaseController.prepend(StubPermissions) unless Folio::Console::BaseController < StubPermissions

  test "renders catalogue wrapper for empty collection" do
    html = cell("folio/console/boutique/orders/catalogue", Boutique::Order.none).(:show)
    assert html.has_css?(".f-c-b-orders-catalogue")
  end

  test "renders catalogue for order without refunds" do
    order = create(:boutique_order, :paid)
    html = cell("folio/console/boutique/orders/catalogue", Boutique::Order.where(id: order.id)).(:show)
    assert html.has_css?(".f-c-b-orders-catalogue")
    refute html.has_css?("s"), "Empty refunds column should not render a <s> element"
  end

  test "renders link with document_number for paid refund" do
    refund = create(:boutique_order_refund, :paid)
    html = cell("folio/console/boutique/orders/catalogue", Boutique::Order.where(id: refund.order.id)).(:show)
    assert html.has_link?(refund.document_number),
           "Expected catalogue to contain a link with text #{refund.document_number.inspect}"
  end

  test "renders links for multiple refunds on a single order" do
    # OrderRefund validates that sum of refunds doesnt exceed order total.
    # Default factory creates refund with total_price = order.total_price,
    # so we need partial refunds for both to fit.
    order = create(:boutique_order, :paid, total_price: 200)
    refund1 = create(:boutique_order_refund, :paid, order: order, total_price_in_cents: 8000)
    refund2 = create(:boutique_order_refund, :paid, order: order, total_price_in_cents: 8000)

    html = cell("folio/console/boutique/orders/catalogue", Boutique::Order.where(id: order.id)).(:show)

    assert html.has_link?(refund1.document_number)
    assert html.has_link?(refund2.document_number)
  end

  test "renders cancelled refund with strikethrough and no document_number fallback to id" do
    refund = create(:boutique_order_refund, :cancelled)
    html = cell("folio/console/boutique/orders/catalogue", Boutique::Order.where(id: refund.order.id)).(:show)

    # cancelled refunds have no document_number; render fallback "#<id>"
    fallback_label = "##{refund.id}"
    assert html.has_link?(fallback_label),
           "Expected fallback label #{fallback_label.inspect} for cancelled refund"
    assert html.has_css?("s a", text: fallback_label),
           "Expected cancelled refund link to be wrapped in <s> (strikethrough)"
  end

  test "renders paid refund without strikethrough" do
    refund = create(:boutique_order_refund, :paid)
    html = cell("folio/console/boutique/orders/catalogue", Boutique::Order.where(id: refund.order.id)).(:show)

    refute html.has_css?("s a", text: refund.document_number),
           "Paid refund should NOT be wrapped in <s>"
  end
end
