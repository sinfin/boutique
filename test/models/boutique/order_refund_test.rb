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

  test "after approve! handle payout through PaymentGateway" do
    order = create(:boutique_order, :paid)
    order.payments.create!(payment_gateway_provider: :comgate, remote_id: "987654abc")
    assert_equal %w[paid pending], order.payments.collect(&:aasm_state).sort

    order_payment = order.payments.paid.first
    assert_equal "go_pay", order_payment.payment_gateway_provider

    order_refund = create(:boutique_order_refund, :created, order:, payment_method: "BANK_ACCOUNT")

    order_refund.expects(:handle_refund_by_payment_gateway).returns(true).once

    order_refund.approve!
  end

  test "after approve! handle payout through PayPal" do
    order = create(:boutique_order, :paid)
    order_payment = order.payments.paid.first
    order_payment.update!(payment_gateway_provider: :paypal)

    order_refund = create(:boutique_order_refund, :created, order:, payment_method: "PAYPAL")

    order_refund.expects(:handle_refund_by_paypal).returns(true).once

    order_refund.approve!
  end

  test "after approve! handle payout through Voucher" do
    order = create(:boutique_order, :paid)
    order_payment = order.payments.paid.first
    order_payment.update!(payment_gateway_provider: :paypal)

    order_refund = create(:boutique_order_refund, :created, order:, payment_method: "VOUCHER")

    order_refund.expects(:handle_refund_by_voucher).returns(true).once
    order_refund.expects(:handle_refund_by_paypal).returns(true).never

    order_refund.approve!
  end

  test "#handle_refund_by_payment_gateway" do
    order = create(:boutique_order, :paid)
    order.payments.create!(payment_gateway_provider: :comgate, remote_id: "987654abc")
    assert_equal %w[paid pending], order.payments.collect(&:aasm_state).sort

    order_payment = order.payments.paid.first
    assert_equal "go_pay", order_payment.payment_gateway_provider

    order_refund = create(:boutique_order_refund, :approved_to_pay, order:, payment_method: "BANK_ACCOUNT")

    gw_mock = mock("PaymentGateway").responds_like_instance_of(Boutique::PaymentGateway)
    gw_mock.expects(:payout_order_refund).with(order_refund).returns(true).once
    Boutique::PaymentGateway.expects(:new)
                            .with(order_payment.payment_gateway_provider.to_sym)
                            .returns(gw_mock)
                            .once

    order_refund.send(:handle_refund_by_payment_gateway)
  end

  test "#handle_refund_by_paypal" do
    # PayPal: instrukce k vrácení prostředků do detailu vratky a e-mailu Admina (e-mail zákazníka, částka)
    order_refund = create(:boutique_order_refund, :approved_to_pay, payment_method: "PAYPAL")

    mailer_mock = mock("OrderRefundMailerInstance")
    mailer_mock.expects(:deliver_later).returns(true).once
    Boutique::OrderRefundMailer.expects(:payout_by_paypal).with(order_refund).returns(mailer_mock).once

    order_refund.send(:handle_refund_by_paypal)
  end

  test "#handle_refund_by_voucher" do
    # Voucher: popis poukazu s tokenem a odkaz k vrácení do detailu vratky a e-mailu Admina (e-mail zákazníka, token, částka, platnost)
    # Platnost poukazů 90 dní s možností změnit v nastavení aplikace.

    order_refund = create(:boutique_order_refund, :approved_to_pay, payment_method: "VOUCHER")

    mailer_mock = mock("OrderRefundMailerInstance")
    mailer_mock.expects(:deliver_later).returns(true).once
    Boutique::OrderRefundMailer.expects(:payout_by_voucher).with(order_refund).returns(mailer_mock).once

    order_refund.send(:handle_refund_by_voucher)
  end

  test "verifies sum of refunds against order" do
    order = create(:boutique_order, :paid, total_price: 300)

    _bo_created = create(:boutique_order_refund, :created, order:, total_price: 100)
    _bo_to_pay = create(:boutique_order_refund, :approved_to_pay, order:, total_price: 100)
    _bo_paid = create(:boutique_order_refund, :paid, order:, total_price: 50)
    _bo_cancelled = create(:boutique_order_refund, :cancelled, order:, total_price: 50)

    # cancelled order is not counted
    extra_bo = build(:boutique_order_refund, order:, total_price: 50)
    assert extra_bo.valid?

    extra_bo.total_price = 50.01
    assert extra_bo.invalid?
    assert_includes extra_bo.errors[:total_price], "Suma všech vratek by překročila celkovou sumu objednávky"
  end

  test "validates reason presence" do
    bor = create(:boutique_order_refund)

    assert bor.reason.present?
    assert bor.valid?

    bor.reason = ""
    assert bor.invalid?
  end

  test "succesfull refund flow" do
    bor = create(:boutique_order_refund)

    assert bor.created?
    assert_equal [:approve, :cancel], bor.permitted_event_names.sort

    bor.approve!
    assert bor.approved_to_pay?
    assert_equal [:pay], bor.permitted_event_names.sort

    bor.pay!
    assert bor.paid?

    assert_equal [], bor.permitted_event_names.sort
  end

  test "can be cancelled only until approval" do
    bor = Boutique::OrderRefund.new
    assert bor.created?

    assert bor.permitted_event_names.include?(:cancel)

    (bor.class.all_state_names - [:created]).each do |state|
      bor.aasm_state = state
      assert_not bor.permitted_event_names.include?(:cancel), "state #{state} should not be cancellable"
    end
  end
end
