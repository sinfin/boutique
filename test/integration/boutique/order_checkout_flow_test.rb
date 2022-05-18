# frozen_string_literal: true

require "test_helper"

class Boutique::OrderCheckoutFlowTest < Boutique::ControllerTest
  include Boutique::Test::GoPayApiMocker
  include Devise::Test::IntegrationHelpers

  def setup
    super

    @product = create(:boutique_product)
    go_pay_create_payment_api_call_mock
  end

  test "anonymous - successful payment" do
    post add_order_url, params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to edit_order_url

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "order@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_order_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_find_payment_api_call_mock
    get comeback_go_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to main_app.user_invitation_url
  end

  test "anonymous - offline payment" do
    post add_order_url, params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to edit_order_url

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "order@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_order_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_find_payment_api_call_mock(state: "PAYMENT_METHOD_CHOSEN")
    get comeback_go_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to main_app.user_invitation_url
  end

  test "anonymous - unsuccessful payment" do
    post add_order_url, params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to edit_order_url

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "order@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_order_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_find_payment_api_call_mock(state: "CANCELED")

    get comeback_go_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to order_url(Boutique::Order.first.secret_hash)
  end

  test "user - successful payment" do
    user = create(:folio_user)
    sign_in user

    post add_order_url, params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to edit_order_url

    params = {
      order: {
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_order_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_find_payment_api_call_mock

    get comeback_go_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to order_url(current_order.secret_hash)
  end

  test "user - offline payment" do
    user = create(:folio_user)
    sign_in user

    post add_order_url, params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to edit_order_url

    params = {
      order: {
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_order_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_find_payment_api_call_mock(state: "PAYMENT_METHOD_CHOSEN")

    get comeback_go_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to order_url(current_order.secret_hash)
  end

  test "user - unsuccessful payment" do
    user = create(:folio_user)
    sign_in user

    post add_order_url, params: { product_variant_id: @product.master_variant.id }
    assert_redirected_to edit_order_url

    params = {
      order: {
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
      }
    }

    post confirm_order_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url

    go_pay_find_payment_api_call_mock

    get comeback_go_pay_url(id: 123, order_id: current_order.secret_hash)
    assert_redirected_to order_url(current_order.secret_hash)
  end

  private
    def current_order
      Boutique::Order.last
    end
end
