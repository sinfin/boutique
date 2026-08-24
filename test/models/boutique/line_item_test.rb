# frozen_string_literal: true

require "test_helper"

module Boutique
  class LineItemTest < ActiveSupport::TestCase
    test "default subscription_recurring stays false when config default is false" do
      product = create(:boutique_product_subscription)
      product.master_variant.update!(subscription_period: 1)
      order = create(:boutique_order)
      li = order.line_items.build(product_variant: product.master_variant)
      li.subscription_recurring = nil

      li.validate

      assert_equal false, li.subscription_recurring
    end

    test "default subscription_recurring follows config default" do
      original = Boutique.config.default_subscription_recurring
      Boutique.config.default_subscription_recurring = true

      product = create(:boutique_product_subscription)
      product.master_variant.update!(subscription_period: 1)
      order = create(:boutique_order)
      li = order.line_items.build(product_variant: product.master_variant)
      li.subscription_recurring = nil

      li.validate

      assert_equal true, li.subscription_recurring
    ensure
      Boutique.config.default_subscription_recurring = original
    end

    test "explicit false is not overwritten by config default" do
      original = Boutique.config.default_subscription_recurring
      Boutique.config.default_subscription_recurring = true

      product = create(:boutique_product_subscription)
      product.master_variant.update!(subscription_period: 1)
      order = create(:boutique_order)
      li = order.line_items.build(product_variant: product.master_variant,
                                  subscription_recurring: false)

      li.validate

      assert_equal false, li.subscription_recurring
    ensure
      Boutique.config.default_subscription_recurring = original
    end
  end
end
