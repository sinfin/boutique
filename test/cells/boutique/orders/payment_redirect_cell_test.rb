# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::PaymentRedirectCellTest < Cell::TestCase
  test "show" do
    html = cell("boutique/orders/payment_redirect", "#url").(:show)
    assert html.has_css?(".b-orders-payment-redirect")
  end
end
