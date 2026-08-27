# frozen_string_literal: true

require "test_helper"

class Boutique::CheckoutControllerTest < Boutique::ControllerTest
  include Boutique::Test::GoPayApiMocker

  test "add_item" do
    product = create(:boutique_product)

    assert_equal 0, Boutique::Order.count

    post add_item_checkout_url(product), params: { product_variant_slug: product.master_variant.slug }
    assert_redirected_to cart_checkout_url

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Order.first.line_items.first.amount
  end

  test "crossdomain_add_item" do
    product = create(:boutique_product)

    assert_equal 0, Boutique::Order.count

    get crossdomain_add_item_checkout_url(product_slug: product.slug),
        headers: { "HTTP_REFERER" => Folio::Current.site.env_aware_domain }
    assert_redirected_to cart_checkout_url

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Order.first.line_items.first.amount
  end

  test "remove_item" do
    assert_raises(ActiveRecord::RecordNotFound) do
      delete remove_item_checkout_url(123)
    end

    create_order_with_current_session_id
    assert_equal 1, @order.line_items.count

    delete remove_item_checkout_url(@order.line_items.first.id)

    assert_redirected_to cart_checkout_url
    assert_equal 0, @order.line_items.count
  end

  test "cart" do
    get cart_checkout_url
    assert_response :success

    create_order_with_current_session_id

    get cart_checkout_url
    assert_response :success
  end

  test "refreshed_cart" do
    get refreshed_cart_checkout_url
    assert_response :success
    assert_empty response.parsed_body

    get refreshed_cart_checkout_url(country_code: "SK")
    assert_response :success
    assert_empty response.parsed_body

    create_order_with_current_session_id

    get refreshed_cart_checkout_url(country_code: "SK")
    assert_response :success
    assert_not_empty response.parsed_body
  end

  test "refreshed_cart switches the line item variant" do
    product = create(:boutique_product_subscription)
    monthly = product.master_variant
    monthly.update!(subscription_period: 1, regular_price: 148)
    yearly = create(:boutique_product_variant, product:,
                                               subscription_period: 12,
                                               regular_price: 1480)

    post add_item_checkout_url(product), params: { product_variant_slug: monthly.slug }

    get refreshed_cart_checkout_url(subscription_recurring: "true")
    assert_response :success
    monthly_price = response.parsed_body["data"]["price"]

    get refreshed_cart_checkout_url(boutique_product_variant_id: yearly.id,
                                    subscription_recurring: "true")
    assert_response :success

    assert_includes response.parsed_body["data"].keys, "summary"
    assert_includes response.parsed_body["data"].keys, "price"
    assert_not_equal monthly_price, response.parsed_body["data"]["price"]
  end

  test "refreshed_cart merges host fragments" do
    original = Boutique.config.refreshed_cart_fragments_proc
    Boutique.config.refreshed_cart_fragments_proc = -> (context:, order:) do
      { disclosure: "<p>host fragment</p>" }
    end

    create_order_with_current_session_id

    get refreshed_cart_checkout_url
    assert_response :success

    assert_equal "<p>host fragment</p>", response.parsed_body["data"]["disclosure"]
  ensure
    Boutique.config.refreshed_cart_fragments_proc = original
  end

  test "apply_voucher" do
    post apply_voucher_checkout_url
    assert_redirected_to main_app.root_url

    create_order_with_current_session_id

    post apply_voucher_checkout_url, params: { voucher_code: "TESTCODE" }
    assert_response :success

    create(:boutique_voucher, code: "TESTCODE")

    post apply_voucher_checkout_url, params: { voucher_code: "TESTCODE" }
    assert_response :success
  end

  test "confirm" do
    post confirm_checkout_url
    assert_redirected_to main_app.root_url

    create_order_with_current_session_id
    go_pay_start_transaction_api_call_mock

    assert @order.payments.blank?

    params = {
      order: {
        first_name: "John",
        last_name: "Doe",
        email: "test-1@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address, :with_phone).serializable_hash,
        shipping_method_id: create(:boutique_shipping_method).id
      }
    }

    post confirm_checkout_url, params: params
    assert_redirected_to mocked_go_pay_payment_gateway_url
    assert @order.reload.confirmed?
    assert @order.payments.present?
    assert_equal "go_pay", @order.payments.last.payment_gateway_provider
    assert @order.primary_address.present?
  end

  private
    def create_order_with_current_session_id
      product = create(:boutique_product)
      post add_item_checkout_url(product), params: { product_variant_slug: product.master_variant.slug }
      @order = Boutique::Order.find_by(web_session_id: session.id.public_id) if session && session.id
    end
end
