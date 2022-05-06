# frozen_string_literal: true

require "test_helper"

class Boutique::GoPayControllerTest < Boutique::ControllerTest
  def setup
    super

    @order = create(:boutique_order, :confirmed)
    @payment = @order.payments.create!(remote_id: 123)
  end

  test "comeback with successful payment" do
    go_pay_api_call_mock(result_state: "PAID")

    get comeback_go_pay_url(id: 123)
    assert_redirected_to order_url(@order.secret_hash)
    assert @payment.reload.paid?
    assert @order.reload.paid?
  end

  test "comeback with failed payment" do
    go_pay_api_call_mock(result_state: "CANCELED")

    get comeback_go_pay_url(id: 123)
    assert_redirected_to order_url(@order.secret_hash)
    assert @payment.reload.cancelled?
    assert @order.reload.confirmed?
  end

  test "notify" do
    go_pay_api_call_mock(result_state: "PAID")

    get notify_go_pay_url(id: 123)
    assert_response :success
  end

  private
    def go_pay_api_call_mock(result_state:)
      result = {
        "id" => 123,
        "payment_instrument" => "PAYMENT_CARD",
        "state" => result_state
      }

      Boutique::GoPay::Api.any_instance
                          .expects(:find_payment)
                          .returns(result)
    end
end
