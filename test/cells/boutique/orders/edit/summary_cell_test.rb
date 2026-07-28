# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::Edit::SummaryCellTest < Cell::TestCase
  test "show" do
    order = create(:boutique_order, line_items_count: 1)
    html = cell("boutique/orders/edit/summary", order).(:show)
    assert html.has_css?(".b-orders-edit-summary")
    assert 1, html.find_all(".b-orders-edit-summary__line-item").size

    order = create(:boutique_order, line_items_count: 2)
    html = cell("boutique/orders/edit/summary", order).(:show)
    assert html.has_css?(".b-orders-edit-summary")
    assert 2, html.find_all(".b-orders-edit-summary__line-item").size
  end

  test "show spells out a discounted introductory price" do
    html = cell("boutique/orders/edit/summary", intro_order(intro_price: 39)).(:show)

    assert_equal "39 Kč po dobu prvních 2 měsíců, poté 149 Kč měsíčně",
                 html.find(".b-orders-edit-summary__intro").text.squish

    # both prices are emphasised, i.e. the markup is not escaped away
    assert_equal ["39 Kč", "149 Kč"],
                 html.find_all(".b-orders-edit-summary__intro strong").map { |el| el.text.squish }

    assert_equal "Nyní zaplatíte: 39 Kč",
                 html.find(".b-orders-edit-summary__line-items-price").text.squish
  end

  test "show spells out a free introductory price" do
    html = cell("boutique/orders/edit/summary", intro_order(intro_price: 0)).(:show)

    assert_equal "ZDARMA po dobu prvních 2 měsíců, poté 149 Kč měsíčně",
                 html.find(".b-orders-edit-summary__intro").text.squish

    # "zdarma" would read as if the whole subscription were free
    assert_equal "Nyní zaplatíte: 0 Kč",
                 html.find(".b-orders-edit-summary__line-items-price").text.squish
  end

  test "show uses the subscription period for the subsequent price" do
    order = intro_order(intro_price: 39, subscription_period: 12, intro_duration_months: 12)

    html = cell("boutique/orders/edit/summary", order).(:show)

    assert_equal "39 Kč po dobu prvních 12 měsíců, poté 149 Kč ročně",
                 html.find(".b-orders-edit-summary__intro").text.squish
  end

  test "show leaves out the introductory note without an introductory price" do
    order = create(:boutique_order, line_items_count: 1)

    html = cell("boutique/orders/edit/summary", order).(:show)

    assert_not html.has_css?(".b-orders-edit-summary__intro")
    assert_not html.has_text?("Nyní zaplatíte")
  end

  private
    def intro_order(intro_price:, subscription_period: 1, intro_duration_months: 2)
      product = create(:boutique_product_subscription,
                       regular_price: 149,
                       subscription_period:,
                       intro_enabled: true,
                       intro_price:,
                       intro_duration_months:)

      order = create(:boutique_order, line_items_count: 0)
      order.line_items << build(:boutique_line_item, product:, order:)
      order.save!
      order
    end
end
