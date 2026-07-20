# frozen_string_literal: true

require "test_helper"

class Boutique::PaymentGatewaysControllerTest < Boutique::ControllerTest
  include Boutique::Test::GoPayApiMocker
  include Boutique::Test::StripeApiMocker

  def setup
    super

    @order = create(:boutique_order, :confirmed)
    @payment = @order.payments.create!(remote_id: 123)
  end

  test "comeback with successful payment" do
    go_pay_check_transaction_api_call_mock

    get return_after_pay_url(id: 123, order_id: @order.secret_hash)

    assert_redirected_to main_app.user_invitation_url
    assert @payment.reload.paid?
    assert @order.reload.paid?
    assert_equal "Platba proběhla úspěšně.", flash[:success]
  end

  test "comeback with failed payment" do
    go_pay_check_transaction_api_call_mock(state: :cancelled)

    get return_after_pay_url(id: 123, order_id: @order.secret_hash)

    assert_redirected_to order_url(@order.secret_hash)
    assert @payment.reload.cancelled?
    assert @order.reload.confirmed?
    assert_equal "Platba selhala.", flash[:alert]
  end

  test "comeback with offline payment" do
    go_pay_check_transaction_api_call_mock(state: :payment_method_chosen)

    get return_after_pay_url(id: 123, order_id: @order.secret_hash)

    assert_redirected_to main_app.user_invitation_url
    assert @payment.reload.pending?
    assert @order.reload.waiting_for_offline_payment?
    assert_equal "Platba proběhla úspěšně.", flash[:success]
  end

  test "payment callback" do
    go_pay_check_transaction_api_call_mock

    assert_not @order.paid?

    get payment_callback_url(id: 123, order_id: @order.secret_hash)

    assert_response :success
    assert @order.reload.paid?
  end

  test "stripe comeback with successful payment" do
    stripe_order = create(:boutique_order, :confirmed)
    stripe_payment = stripe_order.payments.create!(remote_id: mocked_stripe_session_id,
                                                   payment_gateway_provider: "stripe")

    stripe_check_transaction_api_call_mock

    get return_after_pay_url(order_id: stripe_order.secret_hash, session_id: mocked_stripe_session_id)

    assert_redirected_to main_app.user_invitation_url
    assert stripe_payment.reload.paid?
    assert stripe_order.reload.paid?
    assert_equal "Platba proběhla úspěšně.", flash[:success]
  end

  test "stripe comeback with cancelled payment" do
    stripe_order = create(:boutique_order, :confirmed)
    stripe_payment = stripe_order.payments.create!(remote_id: mocked_stripe_session_id,
                                                   payment_gateway_provider: "stripe")

    stripe_check_transaction_api_call_mock(state: :pending)

    get return_after_pay_url(order_id: stripe_order.secret_hash, session_id: mocked_stripe_session_id)

    assert_redirected_to order_url(stripe_order.secret_hash)
    assert stripe_payment.reload.pending?
    assert stripe_order.reload.confirmed?
    assert_equal "Platba selhala.", flash[:alert]
  end
end
