# frozen_string_literal: true

require "test_helper"

class Boutique::SubscriptionBotTest < ActiveSupport::TestCase
  include Boutique::Test::GoPayApiMocker

  def setup
    create(:folio_site)
    @bot = Boutique::SubscriptionBot.new
  end

  test "subscriptions_eligible_for_recurrent_payment_all" do
    assert_equal [], @bot.send(:subscriptions_eligible_for_recurrent_payment_all).map(&:id).sort

    targets = []

    {
      subscriptions_eligible_for_recurrent_payment_first_try: 0.days,
      subscriptions_eligible_for_recurrent_payment_second_try: 1.day,
      subscriptions_eligible_for_recurrent_payment_third_try: 2.days,
      subscriptions_eligible_for_recurrent_payment_fourth_try: 3.days,
    }.each do |key, days|
      assert_equal [], @bot.send(key).map(&:id)

      target = create(:boutique_subscription, active_until: now + 6.hours - days)
      cancelled = create(:boutique_subscription, active_until: now + 6.hours - days, cancelled_at: 1.minute.ago)
      too_old = create(:boutique_subscription, active_until: now + 5.hours - days)
      too_fresh = create(:boutique_subscription, active_until: now + 7.hours - days)

      assert_equal [target.id], @bot.send(key).map(&:id)

      targets << target
    end

    assert_equal targets.map(&:id), @bot.send(:subscriptions_eligible_for_recurrent_payment_all).map(&:id).sort
  end

  # TODO: I do not understand this test
  test "charge_all_eligible" do
    subscription = create(:boutique_subscription, active_until: now + 6.hours)
    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Payment.count

    target_active_until = subscription.active_until # TODO: what is this good for?

    go_pay_repeat_recurring_transaction_api_call_mock
    @bot.charge_all_eligible

    assert_equal 2, Boutique::Order.count
    assert_equal 2, Boutique::Payment.count

    go_pay_repeat_recurring_transaction_api_call_mock
    @bot.charge_all_eligible

    assert_equal 2, Boutique::Order.count
    assert_equal 3, Boutique::Payment.count
  end

  test "charge will create order from previous payment" do
    subscription = create(:boutique_subscription, active_until: now + 6.hours)

    assert subscription.original_order.paid?
    assert_equal subscription.original_order, subscription.current_order
    assert_equal subscription.payment.amount_in_cents, subscription.current_order.total_price * 100
    assert_equal Boutique::Payment.first, subscription.payment

    init_payment = subscription.payment
    assert_equal subscription.original_order, init_payment.order

    expected_created_order = subscription.original_order.dup.tap { |o| o.number = o.number.to_i + 1 } # new order number created during charge
    expected_created_order.line_items = subscription.original_order.line_items.map(&:dup)
    expected_payment_data = payment_data_for(expected_created_order)
    expected_payment_data[:payment][:recurrence] = { init_transaction_id: init_payment.remote_id, period: 2, cycle: :on_demand, valid_to: Date.new(2099, 12, 31) }

    payment_result = Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: "new_payment_id",
      redirect_to: nil,
      hash: { payment: { method: "PAYMENT_CARD" }, state: :pending },
      array: nil
    )

    Boutique::GoPay::UniversalGateway.any_instance
                                     .expects(:repeat_recurring_transaction)
                                     .with(expected_payment_data)
                                     .returns(payment_result) # no block here!
    assert_difference("Boutique::Order.count", 1) do
      assert_difference("Boutique::Payment.count", 1) do
        @bot.charge(subscription.class.where(id: subscription.id))
      end
    end

    assert_equal ["paid", "confirmed"], Boutique::Order.order(id: :asc).pluck(:aasm_state)
    assert_not_equal subscription.original_order, subscription.current_order
    assert subscription.original_order.paid?
    assert subscription.current_order.confirmed?
    assert_nil subscription.recurrent_payments_init_id
  end

  test "charge will create order and payment from subscription if :recurrent_payments_init_id is present " do
    init_id = "init_payment_id"
    subscription = create(:boutique_subscription, active_until: now + 6.hours, payment: nil, recurrent_payments_init_id: init_id)
    p = subscription.payment

    subscription.update(payment: nil)

    assert p.destroy
    subscription.user.primary_address.update!(country_code: "CC") # need 2 chars, not existing "country_code"
    assert subscription.original_order.destroy

    expected_created_order = build_new_order_from(subscription)
    expected_payment_data = payment_data_for(expected_created_order)
    expected_payment_data[:payment][:recurrence] = { init_transaction_id: subscription.recurrent_payments_init_id, period: 1, cycle: :on_demand, valid_to: Date.new(2099, 12, 31) }

    payment_result = Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: "new_payment_id",
      redirect_to: nil,
      hash: { payment: { method: "PAYMENT_CARD" }, state: :pending },
      array: nil
    )

    Boutique::GoPay::UniversalGateway.any_instance
                                      .expects(:repeat_recurring_transaction)
                                      .with(expected_payment_data)
                                      .returns(payment_result) # no block here!
    assert_difference("Boutique::Order.count", 1) do
      assert_difference("Boutique::Payment.count", 2) do # one is "fake" original and second for current payment
        @bot.charge(subscription.class.where(id: subscription.id))
      end
    end

    assert_equal subscription.reload.original_order, subscription.current_order

    new_order = subscription.current_order.reload
    fake_original_payment = new_order.payments.last
    new_payment = new_order.payments.first

    assert new_order.confirmed?

    assert_equal fake_original_payment, new_order.original_payment
    assert_equal init_id, fake_original_payment.remote_id
    assert_equal "fake_init_payment", fake_original_payment.payment_method
    assert_equal "import", fake_original_payment.payment_gateway_provider
    assert fake_original_payment.paid?

    assert_equal "new_payment_id", new_payment.remote_id
    assert_equal "PAYMENT_CARD", new_payment.payment_method
    assert_equal "go_pay", new_payment.payment_gateway_provider
    assert new_payment.pending?
  end

  private
    def now
      @now ||= Time.current.beginning_of_hour + 30.minutes
    end

    def payment_data_for(order)
      {
        payer: {
          email: order.email,
          phone: order.primary_address.phone,
          # first_name: order.user.first_name,
          # last_name: order.user.last_name,
          first_name: order.first_name,
          last_name: order.last_name,
          city: order.primary_address.city,
          street_line: [order.primary_address.address_line_1, order.primary_address.address_line_2].compact.join(", "),
          postal_code: order.primary_address.zip,
          country_code2: order.primary_address.country_code
        },
        payment: {
          currency: "CZK",
          amount_in_cents: order.total_price * 100,
          label: order.to_label,
          reference_id: order.number,
          description: "#{order.model_name.human} #{order.to_label}",
          method: nil,
          product_name: order.model_name.human,
        },
        options: {
          country_code: "CZ",
          language_code: "cs",
          shop_return_url: nil,
          callback_url: nil
        },
        items: line_items_data(order.line_items)
      }
    end

    def line_items_data(line_items)
      return nil if line_items.blank?

      line_items.collect do |li|
        {
          type: "ITEM",
          name: li.title,
          price_in_cents: li.price * 100,
          count: li.amount,
          vat_rate_percent: li.vat_rate_value.to_i,
        }
      end
    end

    def build_new_order_from(subscription)
      user = subscription.user
      new_order = subscription.orders.build(folio_user_id: user.id,
                                            first_name: user.first_name,
                                            last_name: user.last_name,
                                            email: user.email,
                                            use_secondary_address: false)
      new_order.line_items.build(product_variant: subscription.product_variant,
                                 amount: 1,
                                 subscription_recurring: true,
                                 subscription_period: subscription.period)
      new_order.site = subscription.product.site
      new_order.primary_address = user.primary_address.dup
      new_order.secondary_address = nil

      year_prefix = Date.today.year.to_s.last(2)
      new_order.base_number = ActiveRecord::Base.currval("boutique_orders_base_number_seq") + 1
      new_order.number = year_prefix + new_order.base_number.to_s.rjust(5, "0")

      new_order
    end
end
