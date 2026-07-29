# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::Orders::ShowForModelCellTest < Folio::Console::CellTest
  test "show" do
    order = create(:boutique_order, :paid)
    html = cell("folio/console/boutique/orders/show_for_model", order).(:show)
    assert html.has_css?(".f-c-b-orders-show-for-model")
  end

  test "spells out a free introductory price" do
    html = show(paid_intro_order(intro_price: 0, intro_duration_months: 2))

    assert html.has_text?("zdarma po dobu 2 měsíců, poté 149 Kč")
  end

  test "spells out a discounted introductory price" do
    html = show(paid_intro_order(intro_price: 49, intro_duration_months: 3))

    assert html.has_text?("49 Kč po dobu 3 měsíců, poté 149 Kč")
  end

  test "says nothing about an order bought for the full price" do
    html = show(paid_intro_order)

    assert_not html.has_text?("po dobu")
  end

  private
    def show(order)
      cell("folio/console/boutique/orders/show_for_model", order).(:show)
    end

    def paid_intro_order(intro_price: nil, intro_duration_months: nil)
      product = create(:boutique_product_subscription,
                       digital_only: true,
                       subscription_period: 1,
                       regular_price: 149,
                       intro_enabled: intro_price.present?,
                       intro_price:,
                       intro_duration_months:)

      order = create(:boutique_order, :ready_to_be_confirmed, :with_user,
                                      line_items_count: 0,
                                      digital_only: true)
      order.line_items << build(:boutique_line_item, product:, order:)
      order.save!

      assert order.confirm!, order.errors.full_messages.to_sentence
      order.pay!

      order.reload
    end
end
