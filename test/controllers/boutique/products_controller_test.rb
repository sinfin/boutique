# frozen_string_literal: true

require "test_helper"

class Boutique::ProductsControllerTest < Boutique::ControllerTest
  test "show - user gets redirected to cart" do
    product = create(:boutique_product)

    assert_equal 0, Boutique::Order.count

    get product_url(product)
    assert_redirected_to crossdomain_add_order_url(product)
    follow_redirect!
    assert_redirected_to edit_order_url

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Order.first.line_items.first.amount
  end

  test "show - social media crawler gets rendered template with meta tags" do
    product = create(:boutique_product, title: "Title",
                                        meta_title: "Meta Title",
                                        meta_description: "Meta Description",
                                        og_title: "OG Title")

    get product_url(product), headers: { "HTTP_USER_AGENT" => "facebookexternalhit/1.1" }

    assert_response :success
    assert_includes response.body, product.title
    assert_includes response.body, product.meta_title
    assert_includes response.body, product.meta_description
    assert_includes response.body, product.og_title

    # verify no order was created (no redirect happened)
    assert_equal 0, Boutique::Order.count
  end
end
