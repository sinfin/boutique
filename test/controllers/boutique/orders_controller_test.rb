# frozen_string_literal: true

require "test_helper"

class Boutique::OrdersControllerTest < Boutique::ControllerTest
  include Boutique::Test::GoPayApiMocker

  test "add" do
    product = create(:boutique_product)

    assert_equal 0, Boutique::Order.count

    post add_order_url(product)
    assert_redirected_to edit_order_url

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Order.first.line_items.first.amount
  end

  test "crossdomain_add" do
    product = create(:boutique_product)

    assert_equal 0, Boutique::Order.count

    get crossdomain_add_order_url(product),
        headers: { "HTTP_REFERER" => Folio::Site.instance.env_aware_domain }
    assert_redirected_to edit_order_url

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Order.first.line_items.first.amount
  end

  test "edit" do
    get edit_order_url
    assert_redirected_to main_app.root_url

    create_order_with_current_session_id

    get edit_order_url
    assert_response :success
  end

  test "edit offers the payment gateway for a free introductory subscription" do
    product = create(:boutique_product_subscription,
                     regular_price: 149,
                     subscription_period: 1,
                     intro_enabled: true,
                     intro_price: 0,
                     intro_duration_months: 2)

    create_order_with_current_session_id(product:)

    # the enabled methods are pulled from the gateway, which is never called in
    # tests - see Boutique::Orders::PaymentMethodsCell#enabled_payment_methods
    Boutique::Orders::PaymentMethodsCell.any_instance
                                        .stubs(:enabled_payment_methods)
                                        .returns(%w[PAYMENT_CARD BANK_ACCOUNT])

    get edit_order_url
    assert_response :success

    # the card has to be authorized even though nothing is charged, so the
    # plain "order for free" button would be a dead end
    assert_select ".b-orders-payment-methods-price", text: /ZDARMA/
    assert_select ".b-orders-edit__payment input[type=submit]", false

    # and calling that authorization a payment would be a lie
    labels = css_select(".b-orders-payment-methods__submit-btn").map { |btn| btn.text.squish }
    assert_equal ["Ověřit kartu", "Bankovní převod"], labels
  end

  test "refreshed_edit" do
    get refreshed_edit_order_url
    assert_redirected_to main_app.root_url

    create_order_with_current_session_id

    assert_raises(ActionController::ParameterMissing) do
      get refreshed_edit_order_url
    end

    get refreshed_edit_order_url(country_code: "SK")
    assert_response :success

    @order.line_items.all? { |li| li.product.update!(digital_only: true) }
    get refreshed_edit_order_url
    assert_response :success
  end

  test "apply_voucher" do
    post apply_voucher_order_url
    assert_redirected_to main_app.root_url

    create_order_with_current_session_id

    post apply_voucher_order_url, params: { voucher_code: "TESTCODE" }
    assert_response :success

    create(:boutique_voucher, code: "TESTCODE")

    post apply_voucher_order_url, params: { voucher_code: "TESTCODE" }
    assert_response :success
  end

  test "confirm" do
    post confirm_order_url
    assert_redirected_to main_app.root_url

    create_order_with_current_session_id
    go_pay_create_payment_api_call_mock

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "test-1@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash
      }
    }

    post confirm_order_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url
    assert @order.reload.confirmed?
    assert @order.payments.present?
    assert @order.primary_address.present?
  end

  test "confirm free introductory subscription" do
    product = create(:boutique_product_subscription,
                     regular_price: 149,
                     subscription_period: 1,
                     intro_enabled: true,
                     intro_price: 0,
                     intro_duration_months: 2)

    create_order_with_current_session_id(product:)
    go_pay_create_payment_api_call_mock

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "test-intro@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
        line_items_attributes: [{ id: @order.line_items.first.id, subscription_recurring: true }],
      }
    }

    post confirm_order_url, params: params

    # nothing is charged, but the card still has to be authorized at the gateway
    assert_redirected_to mocked_go_pay_payment_gateway_url
    assert_equal 0, @order.reload.total_price
    assert @order.confirmed?
    assert_equal 1, @order.payments.count
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
    go_pay_create_payment_api_call_mock

    post payment_order_url(order.secret_hash)
    assert_redirected_to mocked_go_pay_payment_gateway_url
    assert order.payments.present?
    assert order.primary_address.present?
  end

  private
    def create_order_with_current_session_id(product: nil)
      product ||= create(:boutique_product)
      post add_order_url(product)
      @order = Boutique::Order.find_by(web_session_id: session.id.public_id) if session && session.id
    end
end
