# frozen_string_literal: true

require "test_helper"

class Boutique::OrdersControllerTest < Boutique::ControllerTest
  include Boutique::Test::GoPayApiMocker

  test "show" do
    order = create(:boutique_order, :ready_to_be_confirmed)
    assert_raises(ActiveRecord::RecordNotFound) { get order_url(order.secret_hash) }

    order.confirm!
    get order_url(order.secret_hash)
    assert_response :success

    order.pay!
    get order_url(order.secret_hash)
    assert_response :success
  end

  test "payment" do
    order = create(:boutique_order, :ready_to_be_confirmed)
    assert_raises(ActiveRecord::RecordNotFound) { get order_url(order.secret_hash) }

    order.confirm!

    go_pay_start_transaction_api_call_mock

    post payment_order_url(order.secret_hash)
    assert_redirected_to mocked_go_pay_payment_gateway_url
    assert order.payments.present?
    assert order.primary_address.present?
  end
end
