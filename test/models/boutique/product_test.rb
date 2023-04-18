# frozen_string_literal: true

require "test_helper"

class Boutique::ProductTest < ActiveSupport::TestCase
  test "current_price" do
    product = create(:boutique_product, regular_price: 100)
    assert_not product.discounted?
    assert_equal 100, product.current_price

    product.discounted_price = 50
    assert product.discounted?
    assert_equal 50, product.current_price

    product.discounted_from = 1.hour.from_now
    assert_not product.discounted?

    product.discounted_from = 1.hour.ago
    assert product.discounted?

    product.discounted_until = 1.minute.ago
    assert_not product.discounted?
  end
end
