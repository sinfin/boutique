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
    go_pay_find_payment_api_call_mock

    get comeback_go_pay_url(id: 123)
    assert_redirected_to main_app.user_invitation_url
    assert @payment.reload.paid?
    assert @order.reload.paid?
  end

  test "comeback with failed payment" do
    go_pay_find_payment_api_call_mock(state: "CANCELED")

    get comeback_go_pay_url(id: 123)
    assert_redirected_to order_url(@order.secret_hash)
    assert @payment.reload.cancelled?
    assert @order.reload.confirmed?
  end

  test "notify" do
    go_pay_find_payment_api_call_mock

    get notify_go_pay_url(id: 123)
    assert_response :success
  end
end
