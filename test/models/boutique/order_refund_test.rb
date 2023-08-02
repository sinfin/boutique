# frozen_string_literal: true

require "test_helper"

class Boutique::OrderRefundTest < ActiveSupport::TestCase
  test "#setup_subscription_refund for subscription order" do
    today_year = Date.today.year
    sub_from = Date.new(today_year, 3, 1)
    sub_from = Date.new(today_year - 1, 3, 1) if Date.today < sub_from
    period = 12
    sub_to = sub_from + period.months
    price_per_day = 42

    order = create(:boutique_order, :paid, subscription_product: true)
    s_li = order.subscription_line_item
    s_li.update!(subscription_starts_at: sub_from,
                 amount: 2,
                 unit_price: price_per_day * (sub_to - sub_from),
                 subscription_period: period)

    _subscription = order.send(:set_up_subscription!)

    bor = build(:boutique_order_refund, order:)

    assert_nil bor.subscription_refund_from
    assert_nil bor.subscription_refund_to
    assert_equal 0, bor.subscriptions_price_in_cents

    refund_from = Date.today - 1.day
    refund_to = refund_from + 10.days

    bor.setup_subscription_refund(refund_from, refund_to)

    assert_equal refund_from, bor.subscription_refund_from
    assert_equal refund_to, bor.subscription_refund_to
    assert_equal (100 * 10 * price_per_day),
                  bor.subscriptions_price_in_cents

    refund_to = sub_to - 2.days

    bor.setup_subscription_refund(refund_from, refund_to)

    assert_equal refund_from, bor.subscription_refund_from
    assert_equal refund_to, bor.subscription_refund_to
    assert_equal (100 * (price_per_day * ((sub_to - refund_from).to_i - 2)).to_i),
                  bor.subscriptions_price_in_cents
  end

  test "#setup_subscription_refund for non subscription order" do
    order = create(:boutique_order, :paid, subscription_product: false)
    bor = build(:boutique_order_refund, order:)

    refund_from = Date.today - 1.day
    refund_to = refund_from + 10.days

    assert_nil bor.subscription_refund_from
    assert_nil bor.subscription_refund_to
    assert_equal 0, bor.subscriptions_price_in_cents

    bor.setup_subscription_refund(refund_from, refund_to)

    assert_nil bor.subscription_refund_from
    assert_nil bor.subscription_refund_to
    assert_equal 0, bor.subscriptions_price_in_cents
  end

  test "validates date range, price against order" do
    sub_from = Date.today - 10.days
    period = 12
    sub_to = sub_from + period.months
    price_per_day = 42

    order = create(:boutique_order, :paid, subscription_product: true)
    s_li = order.subscription_line_item
    s_li.update!(subscription_starts_at: sub_from,
                 amount: 2,
                 unit_price: price_per_day * (sub_to - sub_from),
                 subscription_period: period)
    order.total_price = nil
    order.line_items_price = nil

    _subscription = order.send(:set_up_subscription!)

    bor = build(:boutique_order_refund, order:)

    refund_from = sub_from + 2.days
    refund_to = refund_from + 10.days
    bor.setup_subscription_refund(refund_from, refund_to)

    assert bor.valid?, bor.errors.full_messages

    bor.subscription_refund_from = sub_from
    assert bor.valid?

    bor.subscription_refund_to = sub_to
    assert bor.valid?


    bor.subscription_refund_from = sub_from - 1.day
    assert_not bor.valid?

    bor.subscription_refund_from = sub_to + 1.day
    assert_not bor.valid?


    bor.subscription_refund_from = sub_from
    assert bor.valid?


    bor.subscription_refund_to = sub_from - 1.day
    assert_not bor.valid?

    bor.subscription_refund_to = sub_to + 1.day
    assert_not bor.valid?


    bor.subscription_refund_to = sub_to
    assert bor.valid?

    bor.total_price_in_cents = order.total_price_in_cents + 1
    assert_not bor.valid?
    assert_equal ["musí být méně nebo rovno #{order.total_price}"], bor.errors[:total_price]

    bor.total_price_in_cents = 0
    assert_not bor.valid?
    assert_equal ["musí být větší než 0"], bor.errors[:total_price]

    bor.total_price_in_cents = -1
    assert_not bor.valid?
    assert_equal ["musí být větší než 0"], bor.errors[:total_price]
  end
end
