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

  test "recurrence stays on the discounted intro price inside the intro window" do
    subscription = intro_subscription(intro_price: 49, intro_duration_months: 3)

    # first period ends before intro_until, so the next charge is still intro
    subsequent_order = charge_once(subscription)

    assert_equal 49, subsequent_order.line_items.first.unit_price
  end

  test "recurrence switches to the full price after the intro window" do
    subscription = intro_subscription(intro_price: 49, intro_duration_months: 3)

    # simulate that the whole intro block has already elapsed
    subscription.update!(active_until: subscription.intro_until)

    subsequent_order = charge_once(subscription)

    assert_equal 149, subsequent_order.line_items.first.unit_price
  end

  test "free trial recurrence charges the full price" do
    subscription = intro_subscription(intro_price: 0, intro_duration_months: 2)

    subsequent_order = charge_once(subscription)

    assert_equal 149, subsequent_order.line_items.first.unit_price
  end

  test "recurrence keeps the original price without a snapshot" do
    subscription = intro_subscription(intro_price: nil, intro_duration_months: nil, regular_price: 120)

    subsequent_order = charge_once(subscription)

    assert_nil subscription.price_for_next_period
    assert_equal 120, subsequent_order.line_items.first.unit_price
  end

  test "charge_all_eligible" do
    target = create(:boutique_subscription, active_until: now + 6.hours)
    target_active_until = target.active_until

    assert_equal 1, Boutique::Order.count
    assert_equal 1, Boutique::Payment.count

    go_pay_create_recurrent_payment_api_call_mock
    @bot.charge_all_eligible

    assert_equal 2, Boutique::Order.count
    assert_equal 2, Boutique::Payment.count

    go_pay_create_recurrent_payment_api_call_mock
    @bot.charge_all_eligible

    assert_equal 2, Boutique::Order.count
    assert_equal 3, Boutique::Payment.count
  end

  private
    def now
      @now ||= Time.current.beginning_of_hour + 30.minutes
    end

    def setup_emails
      Rails.application.load_tasks
      Rake::Task["folio:email_templates:idp_seed"].execute

      site = Folio::Site.first
      Rails.application.routes.default_url_options[:host] = site.domain
      Rails.application.routes.default_url_options[:only_path] = false
    end

    def intro_subscription(intro_price:, intro_duration_months:, regular_price: 149)
      setup_emails

      product = create(:boutique_product_subscription,
                       regular_price:,
                       subscription_period: 1,
                       intro_enabled: intro_price.present?,
                       intro_price:,
                       intro_duration_months:)

      order = create(:boutique_order, :ready_to_be_confirmed, :with_user, line_items_count: 0)
      order.line_items << build(:boutique_line_item, product:, order:)
      order.save!

      assert order.confirm!, order.errors.full_messages.to_sentence

      # the paid payment has to exist before pay!, so that set_up_subscription!
      # picks it up as subscription.payment and later recurrences can build on it
      create(:boutique_payment, order:)
      order.pay!

      order.subscription.reload
    end

    # Runs one recurrence and returns the freshly built subsequent order.
    def charge_once(subscription)
      go_pay_create_recurrent_payment_api_call_mock

      assert_difference("subscription.orders.reload.count", 1) do
        @bot.charge(Boutique::Subscription.where(id: subscription.id))
      end

      subscription.current_order
    end
end
