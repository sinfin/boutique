# frozen_string_literal: true

require "test_helper"

class Boutique::ProductsControllerTest < Boutique::ControllerTest
  test "show" do
    product = create(:boutique_product)

    assert_equal 0, Boutique::Order.count

    get product_url(product.master_variant)
    assert_redirected_to crossdomain_add_order_url(product_variant_slug: product.master_variant.slug)
    follow_redirect!
    assert_redirected_to edit_order_url

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Order.first.line_items.first.amount
  end
end
