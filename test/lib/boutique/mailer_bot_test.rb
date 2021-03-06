# frozen_string_literal: true

require "test_helper"

class Boutique::MailerBotTest < ActiveSupport::TestCase
  include Boutique::Test::GoPayApiMocker

  def setup
    create(:folio_site)
    @bot = Boutique::MailerBot.new
  end

  test "orders_unpaid_reminder" do
    assert_equal [], @bot.send(:orders_for_unpaid_reminder).map(&:id)

    target = create(:boutique_order, :confirmed, confirmed_at: now - 1.day)
    paid = create(:boutique_order, :confirmed, confirmed_at: now - 1.day, aasm_state: "paid")
    too_old = create(:boutique_order, :confirmed, confirmed_at: now - 25.hours)
    too_fresh = create(:boutique_order, :confirmed, confirmed_at: now - 23.hours)

    assert_equal [target.id], @bot.send(:orders_for_unpaid_reminder).map(&:id)
  end

  test "subscriptions_will_be_paid_in_a_week" do
    assert_equal [], @bot.send(:subscriptions_for_will_be_paid_in_a_week).map(&:id)

    target = create(:boutique_subscription, active_until: now + 1.week)
    cancelled = create(:boutique_subscription, active_until: now + 1.week, cancelled_at: 1.minute.ago)
    too_old = create(:boutique_subscription, active_until: now + 1.week - 1.day)
    too_fresh = create(:boutique_subscription, active_until: now + 1.week + 1.day)

    assert_equal [target.id], @bot.send(:subscriptions_for_will_be_paid_in_a_week).map(&:id)
  end

  test "subscriptions_failure" do
    assert_equal [], @bot.send(:subscriptions_for_failure).map(&:id)

    target = create(:boutique_subscription, active_until: now - 1.day)
    cancelled = create(:boutique_subscription, active_until: now - 1.day, cancelled_at: 1.minute.ago)
    too_old = create(:boutique_subscription, active_until: now - 2.days)
    too_fresh = create(:boutique_subscription, active_until: now - 1.hour)

    assert_equal [target.id], @bot.send(:subscriptions_for_failure).map(&:id)
  end

  test "subscriptions_unpaid" do
    assert_equal [], @bot.send(:subscriptions_for_unpaid).map(&:id)

    target = create(:boutique_subscription, active_until: now - 15.days)
    cancelled = create(:boutique_subscription, active_until: now - 15.days, cancelled_at: 1.minute.ago)
    too_old = create(:boutique_subscription, active_until: now - 16.days)
    too_fresh = create(:boutique_subscription, active_until: now - 1.day)

    assert_equal [target.id], @bot.send(:subscriptions_for_unpaid).map(&:id)
  end

  private
    def now
      @now ||= Time.current.beginning_of_hour - 30.minutes
    end
end
