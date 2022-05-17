# frozen_string_literal: true

require "test_helper"

class Boutique::SubscriptionBotTest < ActiveSupport::TestCase
  include Boutique::Test::GoPayApiMocker

  def setup
    create(:folio_site)
    @bot = Boutique::SubscriptionBot.new
  end

  test "subscriptions_eligible_for_recurrent_payment_all" do
    assert_equal [], @bot.send(:subscriptions_eligible_for_recurrent_payment_all).map(&:id)

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

    assert_equal targets.map(&:id), @bot.send(:subscriptions_eligible_for_recurrent_payment_all).map(&:id)
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
end
