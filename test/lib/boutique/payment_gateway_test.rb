# frozen_string_literal: true

require "test_helper"

class Boutique::PaymentGatewayTest < ActiveSupport::TestCase

  test "default provider is go_pay" do
    gw = Boutique::PaymentGateway.new

    assert_equal :go_pay, gw.provider
    assert gw.provider_gateway.is_a?(Boutique::GoPay::UniversalGateway)
  end

  test "select gateway according to param" do
    gw = Boutique::PaymentGateway.new(:go_pay)

    assert_equal :go_pay, gw.provider
    assert gw.provider_gateway.is_a?(Boutique::GoPay::UniversalGateway)
    assert_equal true, gw.provider_gateway.test_calls_used?

    gw = Boutique::PaymentGateway.new(:comgate)

    assert_equal :comgate, gw.provider
    assert gw.provider_gateway.is_a?(Comgate::Gateway)
    assert_equal true, gw.provider_gateway.test_calls_used?
  end

  test "#check_transaction(transaction_id)" do
    transaction_id ="ABS-123"
    pgw_response =  Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: transaction_id,
      redirect_to: nil,
      hash: { code: 0, state: :paid },
      array: nil
    )
    gw = Boutique::PaymentGateway.new
    gw.provider_gateway
      .expects(:check_transaction)
      .with(transaction_id: transaction_id)
      .returns(pgw_response)

    resp = gw.check_transaction(transaction_id)

    assert_not resp.redirect?
    assert_equal :paid, resp.hash[:state]
  end

  test "#start_transaction(order)" do
    order = create(:boutique_order, :confirmed)
    transaction_id = "1345679ABCD"
    pgw_response =  Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: transaction_id,
      redirect_to: "https://www.boutique.com",
      hash: { code: 0, message: "OK" },
      array: nil
    )

    gw = Boutique::PaymentGateway.new
    gw.provider_gateway
      .expects(:check_transaction)
      .with(transaction_id: transaction_id)
      .returns(pgw_response)

    resp = gw.start_transaction(order)

    assert resp.redirect?
    assert_equal pgw_response, resp
  end

  test "prepares data for start_recurring_transaction(order)" do
    skip
  end

  test "prepares data for repeat_recurring_transaction(payment_data)" do
    skip
  end

  test "prepares data for process_callback(payload)" do
    skip
  end

  test "prepares data for start_preauthorized_transaction(payment_data)" do
    skip
  end

  test "prepares data for confirm_preauthorized_transaction(payment_data)" do
    skip
  end

  test "prepares data for cancel_preauthorized_transaction(transaction_id)" do
    skip
  end

  test "prepares data for start_verification_transaction(payment_data)" do
    skip
  end

  test "prepares data for refund_transaction(payment_data)" do
    skip
  end

  test "prepares data for cancel_transaction(transaction_id)" do
    skip
  end

  test "prepares data for allowed_payment_methods(params)" do
    skip
  end

  test "handles gateway errors" do
    skip
  end
end
