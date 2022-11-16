# frozen_string_literal: true

require "test_helper"

class Boutique::Subscriptions::RecurrentPaymentLabelCellTest < Cell::TestCase
  test "show" do
    html = cell("boutique/subscriptions/recurrent_payment_label", nil).(:show)
    assert html.has_css?(".b-subscriptions-recurrent-payment-label")
  end
end
