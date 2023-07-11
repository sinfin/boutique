# frozen_string_literal: true

require "test_helper"

class Boutique::OrderCheckoutFlowTest < Boutique::ControllerTest
  include Boutique::Test::GoPayApiMocker
  include Devise::Test::IntegrationHelpers

  def setup
    super

    @product = create(:boutique_product)
    @shipping_method = create(:boutique_shipping_method)
    go_pay_start_transaction_api_call_mock

    @default_after_order_paid_redirect_url_proc = Boutique.config.after_order_paid_redirect_url_proc
    Boutique.config.after_order_paid_redirect_url_proc = -> (controller:, order:) { "/custom-url" }
  end

  teardown do
    Boutique.config.after_order_paid_redirect_url_proc = @default_after_order_paid_redirect_url_proc
  end

  test "anonymous - successful payment" do
    post add_item_checkout_url(@product), params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to cart_checkout_url

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "order@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_checkout_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_check_transaction_api_call_mock(state: :paid)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)

    assert_redirected_to main_app.user_invitation_url
    assert current_order.reload.paid?
  end

  test "anonymous - offline payment" do
    post add_item_checkout_url(@product), params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to cart_checkout_url

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "order@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_checkout_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_check_transaction_api_call_mock(state: :payment_method_chosen)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to main_app.user_invitation_url
    assert_not current_order.reload.paid?
  end

  test "anonymous - unsuccessful payment" do
    post add_item_checkout_url(@product), params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to cart_checkout_url

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "order@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_checkout_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_check_transaction_api_call_mock(state: :cancelled)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to order_url(Boutique::Order.first.secret_hash)
    assert_not current_order.reload.paid?
  end

  test "user - successful payment" do
    user = create(:folio_user)
    sign_in user

    post add_item_checkout_url(@product), params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to cart_checkout_url

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        # not needed for signed in user:    email: "order@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_checkout_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_check_transaction_api_call_mock(state: :paid)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to "/custom-url"
    assert current_order.reload.paid?
  end

  test "user - offline payment" do
    user = create(:folio_user)
    sign_in user

    post add_item_checkout_url(@product), params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to cart_checkout_url

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        # not needed for signed in user:    email: "order@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_checkout_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_check_transaction_api_call_mock(state: :payment_method_chosen)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to "/custom-url"
    assert_not current_order.reload.paid?
  end

  test "user - unsuccessful payment" do
    user = create(:folio_user)
    sign_in user

    post add_item_checkout_url(@product), params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to cart_checkout_url

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        # not needed for signed in user:    email: "order@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_checkout_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_check_transaction_api_call_mock(state: :cancelled)

    get return_after_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to order_url(current_order.secret_hash)
    assert_not current_order.reload.paid?
  end

  private
    def current_order
      Boutique::Order.last
    end
end
