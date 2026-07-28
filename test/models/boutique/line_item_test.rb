# frozen_string_literal: true

require "test_helper"

module Boutique
  class LineItemTest < ActiveSupport::TestCase
    setup do
      @product = create(:boutique_product_subscription,
                        regular_price: 149,
                        subscription_period: 1,
                        intro_enabled: true,
                        intro_price: 49,
                        intro_duration_months: 3)
    end

    test "unit_price uses the introductory price for a new subscription" do
      line_item = build_line_item

      assert line_item.intro_applicable?
      assert_equal 49, line_item.unit_price
      assert_equal 149, line_item.unit_price_without_discount
    end

    test "unit_price ignores the introductory price for a product without one" do
      @product.update!(intro_enabled: false)

      line_item = build_line_item

      assert_not line_item.intro_applicable?
      assert_equal 149, line_item.unit_price
    end

    test "unit_price ignores the introductory price for a non subscription product" do
      line_item = build_line_item(product: create(:boutique_product, regular_price: 149))

      assert_not line_item.intro_applicable?
      assert_equal 149, line_item.unit_price
    end

    test "unit_price ignores the introductory price when prolonging a subscription" do
      line_item = build_line_item
      line_item.order.renewed_subscription = create(:boutique_subscription)

      assert_not line_item.intro_applicable?
      assert_equal 149, line_item.unit_price
    end

    test "unit_price ignores the introductory price for a gift" do
      line_item = build_line_item(order: create(:boutique_order, :gift))

      assert_not line_item.intro_applicable?
      assert_equal 149, line_item.unit_price
    end

    test "unit_price ignores the introductory price without recurring payment" do
      line_item = build_line_item(subscription_recurring: false)

      assert_not line_item.intro_applicable?
      assert_equal 149, line_item.unit_price

      # not decided yet - the introductory price stays visible during checkout
      line_item.subscription_recurring = nil
      assert line_item.intro_applicable?
      assert_equal 49, line_item.unit_price
    end

    test "imprint freezes the introductory price" do
      line_item = build_line_item
      line_item.imprint

      @product.update!(intro_price: 99)

      assert_equal 49, line_item.unit_price
    end

    test "imprint snapshots the introductory duration and the subsequent price" do
      line_item = build_line_item
      line_item.imprint

      assert_equal 3, line_item.intro_duration_months
      assert_equal 149, line_item.subsequent_unit_price
      assert_not line_item.free_intro?

      @product.update!(regular_price: 199, intro_duration_months: 6)

      assert_equal 3, line_item.intro_duration_months
      assert_equal 149, line_item.subsequent_unit_price
    end

    test "imprint leaves the snapshots empty without an introductory price" do
      @product.update!(intro_enabled: false, discounted_price: 99)

      line_item = build_line_item
      line_item.imprint

      # a subscription bought for a discounted price has to keep renewing for it,
      # so there must be no subsequent price to switch to
      assert_equal 99, line_item.unit_price
      assert_nil line_item.intro_duration_months
      assert_nil line_item.subsequent_unit_price
      assert_not line_item.free_intro?
    end

    test "the introductory snapshots fall back to the product during checkout" do
      line_item = build_line_item

      # the checkout has to be able to spell out the introductory terms before
      # imprint gets to write them down
      assert line_item.intro?
      assert_equal 3, line_item.intro_duration_months
      assert_equal 149, line_item.subsequent_unit_price
    end

    test "the introductory snapshots stay empty once the order is confirmed" do
      @product.update!(intro_enabled: false)

      order = create(:boutique_order, :ready_to_be_confirmed, line_items_count: 0)
      order.line_items << build(:boutique_line_item, product: @product, order:)
      order.save!
      assert order.confirm!, order.errors.full_messages.to_sentence

      # the product gaining an introductory price later must not rewrite what
      # the customer actually bought
      @product.update!(intro_enabled: true, intro_price: 49, intro_duration_months: 3)

      line_item = order.line_items.first.reload

      assert_not line_item.intro?
      assert_nil line_item.intro_duration_months
      assert_nil line_item.subsequent_unit_price
    end

    test "free_intro? for a zero introductory price" do
      @product.update!(intro_price: 0)

      line_item = build_line_item

      # already during checkout, before imprint writes the snapshots
      assert line_item.free_intro?

      line_item.imprint

      assert_equal 0, line_item.unit_price
      assert line_item.free_intro?
    end

    test "free_intro? is false for a product that is free without an introductory price" do
      line_item = build_line_item(product: create(:boutique_product_subscription, regular_price: 0))

      assert_equal 0, line_item.unit_price
      assert_not line_item.free_intro?
    end

    test "confirmed order totals the introductory price" do
      order = create(:boutique_order, :ready_to_be_confirmed, line_items_count: 0)
      order.line_items << build(:boutique_line_item, product: @product, order:)
      order.save!

      assert order.confirm!, order.errors.full_messages.to_sentence
      assert_equal 49, order.line_items.first.unit_price
      assert_equal 49, order.total_price
    end

    private
      def build_line_item(product: @product, order: nil, **attributes)
        build(:boutique_line_item,
              product:,
              order: order || create(:boutique_order),
              **attributes)
      end
  end
end
