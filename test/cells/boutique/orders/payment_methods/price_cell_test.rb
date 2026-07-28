# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::PaymentMethods::PriceCellTest < Cell::TestCase
  test "show" do
    order = create(:boutique_order, line_items_count: 0)
    order.line_items << build(:boutique_line_item,
                              product: create(:boutique_product, regular_price: 149),
                              order:)
    order.save!

    html = cell("boutique/orders/payment_methods/price", order).(:show)

    assert_equal "Platba 149 Kč",
                 html.find(".b-orders-payment-methods-price").text.squish
  end

  test "show appends the introductory terms to a discounted introductory price" do
    order = intro_order(intro_price: 39)

    html = cell("boutique/orders/payment_methods/price", order).(:show)

    assert_equal "Platba 39 Kč po dobu prvních 2 měsíců, poté 149 Kč měsíčně",
                 html.find(".b-orders-payment-methods-price").text.squish

    # the price after the introductory period is emphasised, the rest is not
    assert_equal "149 Kč",
                 html.find(".b-orders-payment-methods-price__intro strong").text.squish
  end

  test "show replaces the title for a free introductory price" do
    order = intro_order(intro_price: 0)

    # "Platba 0 Kč" would suggest a payment that never happens
    html = cell("boutique/orders/payment_methods/price", order).(:show)

    assert_equal "ZDARMA po dobu prvních 2 měsíců, poté 149 Kč měsíčně",
                 html.find(".b-orders-payment-methods-price").text.squish
  end

  private
    def intro_order(intro_price:)
      product = create(:boutique_product_subscription,
                       regular_price: 149,
                       subscription_period: 1,
                       intro_enabled: true,
                       intro_price:,
                       intro_duration_months: 2)

      order = create(:boutique_order, line_items_count: 0)
      order.line_items << build(:boutique_line_item, product:, order:)
      order.save!
      order
    end
end
