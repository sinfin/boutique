# frozen_string_literal: true

require "test_helper"

class Boutique::GoPayControllerTest < Boutique::ControllerTest
  include Boutique::Test::GoPayApiMocker

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
  end

  test "comeback with failed payment" do
    go_pay_check_transaction_api_call_mock(state: :cancelled)

    get return_after_pay_url(id: 123, order_id: @order.secret_hash)
    assert_redirected_to order_url(@order.secret_hash)
    assert @payment.reload.cancelled?
    assert @order.reload.confirmed?
  end

  test "comeback with offline payment" do
    go_pay_check_transaction_api_call_mock(state: :payment_method_chosen)

    get return_after_pay_url(id: 123, order_id: @order.secret_hash)
    assert_redirected_to main_app.user_invitation_url
    assert @payment.reload.pending?
    assert @order.reload.waiting_for_offline_payment?
  end

  test "notify" do
    go_pay_check_transaction_api_call_mock

    get notify_go_pay_url(id: 123, order_id: @order.secret_hash)
    assert_response :success
  end
end
