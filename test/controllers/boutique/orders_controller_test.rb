# frozen_string_literal: true

require "test_helper"

class Boutique::OrdersControllerTest < ActionDispatch::IntegrationTest
  include Boutique::Engine.routes.url_helpers

  setup do
    create(:folio_site)
  end

  test "add" do
    product = create(:boutique_product)

    assert_equal 0, Boutique::Order.count

    post add_order_url, params: { product_variant_id: product.master_variant.id }
    assert_redirected_to order_url

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Order.first.line_items.first.amount

    post add_order_url, params: { product_variant_id: product.master_variant.id, amount: 2 }
    assert_redirected_to order_url
    assert_equal 1, Boutique::Order.count
    assert_equal 3, Boutique::Order.first.line_items.first.amount
  end

  test "show" do
    get order_url
    assert_response :success

    create_order_with_current_session_id
    get order_url
    assert_response :success
  end

  test "edit" do
    get edit_order_url
    assert_redirected_to order_url

    create_order_with_current_session_id

    get edit_order_url
    assert_response :success
  end

  test "confirm" do
    post confirm_order_url
    assert_redirected_to order_url

    create_order_with_current_session_id

    params = {
      order: {
        email: "test-1@test.test",
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash
      }
    }

    post confirm_order_url, params: params
    assert_redirected_to thank_you_order_url(id: @order.reload.number)
    assert @order.confirmed?
    assert @order.primary_address.present?
  end

  private
    def create_order_with_current_session_id
      product = create(:boutique_product)
      post add_order_url, params: { product_variant_id: product.master_variant.id }
      @order = Boutique::Order.find_by(web_session_id: session.id.public_id)
    end
end
