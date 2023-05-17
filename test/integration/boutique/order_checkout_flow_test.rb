# frozen_string_literal: true

require "test_helper"

class Boutique::OrderCheckoutFlowTest < Boutique::ControllerTest
  include Boutique::Test::GoPayApiMocker
  include Devise::Test::IntegrationHelpers

  def setup
    super

    @product = create(:boutique_product, digital_only: true) # TODO: remove digital only and pass shipment params, after introducing Shipping
    go_pay_start_transaction_api_call_mock
  end

  test "anonymous - successful payment" do
    post add_order_url(@product), params: { product_variant_id: @product.master_variant.id }

    assert_redirected_to edit_order_url

    post confirm_order_url, params: checkout_params.deep_merge({ order: { email: "order@test.test" } })

    assert_redirected_to mocked_go_pay_payment_gateway_url
    go_pay_check_transaction_api_call_mock(state: :paid)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)

    assert_redirected_to main_app.user_invitation_url
    assert current_order.reload.dispatched?
    assert current_order.paid_at.present?
  end

  test "anonymous - offline payment" do
    post add_order_url(@product), params: { product_variant_id: @product.master_variant.id }

    assert_redirected_to edit_order_url

    post confirm_order_url, params: checkout_params.deep_merge({ order: { email: "order@test.test" } })

    assert_redirected_to mocked_go_pay_payment_gateway_url
    go_pay_check_transaction_api_call_mock(state: :payment_method_chosen)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)

    assert_redirected_to main_app.user_invitation_url
    assert_not current_order.reload.confirmed?
    assert current_order.paid_at.blank?
  end

  test "anonymous - unsuccessful payment" do
    post add_order_url(@product), params: { product_variant_id: @product.master_variant.id }

    assert_redirected_to edit_order_url

    post confirm_order_url, params: checkout_params.deep_merge({ order: { email: "order@test.test" } })

    assert_redirected_to mocked_go_pay_payment_gateway_url
    go_pay_check_transaction_api_call_mock(state: :cancelled)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)

    assert_redirected_to order_url(Boutique::Order.first.secret_hash)
    assert current_order.reload.confirmed?
    assert current_order.paid_at.blank?
  end

  test "user - successful payment" do
    user = create(:folio_user)
    sign_in user

    post add_order_url(@product), params: { product_variant_id: @product.master_variant.id }

    assert_redirected_to edit_order_url

    post confirm_order_url, params: checkout_params

    assert_redirected_to mocked_go_pay_payment_gateway_url
    go_pay_check_transaction_api_call_mock(state: :paid)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)

    assert_redirected_to send(Boutique.config.after_order_paid_user_url_name)
    assert current_order.reload.dispatched?
    assert current_order.paid_at.present?
  end

  test "user - offline payment" do
    user = create(:folio_user)
    sign_in user

    post add_order_url(@product), params: { product_variant_id: @product.master_variant.id }

    assert_redirected_to edit_order_url

    post confirm_order_url, params: checkout_params

    assert_redirected_to mocked_go_pay_payment_gateway_url
    go_pay_check_transaction_api_call_mock(state: :payment_method_chosen)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)

    assert_redirected_to send(Boutique.config.after_order_paid_user_url_name)
    assert current_order.reload.waiting_for_offline_payment?
    assert current_order.paid_at.blank?
  end

  test "user - unsuccessful payment" do
    user = create(:folio_user)
    sign_in user

    post add_order_url(@product), params: { product_variant_id: @product.master_variant.id }

    assert_redirected_to edit_order_url

    post confirm_order_url, params: checkout_params

    assert_redirected_to mocked_go_pay_payment_gateway_url
    go_pay_check_transaction_api_call_mock(state: :cancelled)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)

    assert_redirected_to order_url(Boutique::Order.first.secret_hash)
    assert current_order.reload.confirmed?
    assert current_order.paid_at.blank?
  end

  private
    def current_order
      Boutique::Order.last
    end

    def checkout_params
      {
        order: {
          first_name: "John",
          last_name: "Doe",
          # not needed for signed in user:    email: "order@test.test",
          primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
          # shipment: {shipping_id: @shipping.id, branch_id: 555}
        }
      }
    end
end
