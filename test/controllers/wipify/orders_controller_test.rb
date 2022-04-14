# frozen_string_literal: true

require "test_helper"

class Wipify::OrdersControllerTest < ActionDispatch::IntegrationTest
  include Wipify::Engine.routes.url_helpers

  test "add" do
    product = create(:wipify_product)

    assert_equal 0, Wipify::Order.count

    post add_order_path, params: { product_variant_id: product.master_variant.id }
    assert_equal 1, Wipify::Order.count
    assert_equal 1, Wipify::Order.first.line_items.first.amount

    post add_order_path, params: { product_variant_id: product.master_variant.id, amount: 2 }
    assert_equal 1, Wipify::Order.count
    assert_equal 3, Wipify::Order.first.line_items.first.amount
  end
end
