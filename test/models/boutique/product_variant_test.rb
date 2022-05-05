# frozen_string_literal: true

require "test_helper"

class Boutique::ProductVariantTest < ActiveSupport::TestCase
  test "current_price" do
    product_variant = create(:boutique_product, price: 100).master_variant
    assert_not product_variant.discounted?
    assert_equal 100, product_variant.current_price

    product_variant.discounted_price = 50
    assert product_variant.discounted?
    assert_equal 50, product_variant.current_price

    product_variant.discounted_from = 1.hour.from_now
    assert_not product_variant.discounted?

    product_variant.discounted_from = 1.hour.ago
    assert product_variant.discounted?

    product_variant.discounted_until = 1.minute.ago
    assert_not product_variant.discounted?
  end
end
