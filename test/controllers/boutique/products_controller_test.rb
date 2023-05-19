# frozen_string_literal: true

require "test_helper"

class Boutique::ProductsControllerTest < Boutique::ControllerTest
  test "show" do
    product = create(:boutique_product)

    assert_equal 0, Boutique::Order.count

    get product_url(product)
    assert_redirected_to crossdomain_add_item_checkout_url(product_slug: product.slug)
    follow_redirect!
    assert_redirected_to cart_checkout_url

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Order.first.line_items.first.amount
  end
end
