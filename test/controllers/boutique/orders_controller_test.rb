# frozen_string_literal: true

require "test_helper"

class Boutique::OrdersControllerTest < Boutique::ControllerTest
  test "add" do
    product = create(:boutique_product)

    assert_equal 0, Boutique::Order.count

    post add_order_url, params: { product_variant_id: product.master_variant.id }
    assert_redirected_to edit_order_url

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Order.first.line_items.first.amount
  end

  test "edit" do
    create(:folio_page, type: "Dummy::Page::DataProtection")
    create(:folio_page, type: "Dummy::Page::Terms")

    get edit_order_url
    assert_redirected_to main_app.root_url

    create_order_with_current_session_id

    get edit_order_url
    assert_response :success
  end

  test "confirm" do
    post confirm_order_url
    assert_redirected_to main_app.root_url

    create_order_with_current_session_id
    go_pay_api_call_mock

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "test-1@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash
      }
    }

    post confirm_order_url, params: params
    assert_redirected_to "https://test.gopay.com"
    assert @order.reload.confirmed?
    assert @order.payments.present?
    assert @order.primary_address.present?
  end

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
    go_pay_api_call_mock

    post payment_order_url(order.secret_hash)
    assert_redirected_to "https://test.gopay.com"
    assert order.payments.present?
    assert order.primary_address.present?
  end

  private
    def create_order_with_current_session_id
      product = create(:boutique_product)
      post add_order_url, params: { product_variant_id: product.master_variant.id }
      @order = Boutique::Order.find_by(web_session_id: session.id.public_id)
    end

    def go_pay_api_call_mock
      result = {
        "id" => 123,
        "payment_instrument" => "PAYMENT_CARD",
        "gw_url" => "https://test.gopay.com",
      }

      Boutique::GoPay::Api.any_instance
                          .expects(:create_payment)
                          .returns(result)
    end
end
