# frozen_string_literal: true

require "test_helper"

class Boutique::MailerBotTest < ActiveSupport::TestCase
  include Boutique::Test::GoPayApiMocker
  include ActiveJob::TestHelper

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

  test "subscriptions_ended" do
    assert_equal [], @bot.send(:subscriptions_for_ended).map(&:id)

    target = create(:boutique_subscription, active_until: now - 1.day, recurrent: false)
    active = create(:boutique_subscription, active_until: now - 1.day, recurrent: true)
    too_old = create(:boutique_subscription, active_until: now - 2.days, recurrent: false)
    too_fresh = create(:boutique_subscription, active_until: now - 1.hour, recurrent: false)

    assert_equal [target.id], @bot.send(:subscriptions_for_ended).map(&:id)
  end

  test "subscriptions_failed_payment" do
    assert_equal [], @bot.send(:subscriptions_for_failed_payment).map(&:id)

    target = create(:boutique_subscription, active_until: now - 12.hours, recurrent: true)
    cancelled = create(:boutique_subscription, active_until: now - 12.hours, recurrent: false)
    too_old = create(:boutique_subscription, active_until: now - 1.day, recurrent: true)
    too_fresh = create(:boutique_subscription, active_until: now - 1.hour, recurrent: true)

    assert_equal [target.id], @bot.send(:subscriptions_for_failed_payment).map(&:id)
  end

  test "subscriptions_for_unpaid" do
    assert_equal [], @bot.send(:subscriptions_for_unpaid).map(&:id)

    target = create(:boutique_subscription, active_until: now - 7.days, recurrent: true)
    cancelled = create(:boutique_subscription, active_until: now - 7.days, recurrent: false)
    too_old = create(:boutique_subscription, active_until: now - 8.days, recurrent: true)
    too_fresh = create(:boutique_subscription, active_until: now - 1.day, recurrent: true)

    assert_equal [target.id], @bot.send(:subscriptions_for_unpaid).map(&:id)
  end

  test "subscriptions_unpaid - skip emails if there are newer subscription" do
    target_with_newer_sub = create(:boutique_subscription, active_until: now - 7.days, recurrent: true)
    newer_sub = create(:boutique_subscription, boutique_product_variant_id: target_with_newer_sub.boutique_product_variant_id,
                                               user: target_with_newer_sub.user,
                                               active_until: now + 1.day,
                                               recurrent: true)
    # 1
    target_without_newer_sub = create(:boutique_subscription, active_until: now - 7.days, recurrent: true)
    # 2
    target_without_newer_sub_by_user = create(:boutique_subscription, active_until: now - 7.days, recurrent: true)
    other_user_newer_sub = create(:boutique_subscription, boutique_product_variant_id: target_without_newer_sub_by_user.boutique_product_variant_id,
                                                          active_until: now + 7.days,
                                                          recurrent: true)
    assert_not_equal target_without_newer_sub_by_user.folio_user_id, other_user_newer_sub.folio_user_id
    # 3
    target_without_newer_sub_by_product = create(:boutique_subscription, active_until: now - 7.days, recurrent: true)
    other_user_newer_sub = create(:boutique_subscription, user: target_with_newer_sub.user,
                                                          active_until: now + 7.days,
                                                          recurrent: true)
    assert_not_equal target_without_newer_sub_by_product.boutique_product_variant_id, other_user_newer_sub.boutique_product_variant_id
    # 4
    target_without_newer_sub_by_time = create(:boutique_subscription, active_until: now - 7.days, recurrent: true)
    newer_sub = create(:boutique_subscription, boutique_product_variant_id: target_with_newer_sub.boutique_product_variant_id,
                                               user: target_with_newer_sub.user,
                                               active_until: now - 1.minute,
                                               recurrent: true)

    assert_enqueued_jobs 4, only: ActionMailer::MailDeliveryJob do
      @bot.subscriptions_unpaid
    end

    mailed_sub_ids = enqueued_jobs.collect { |job| job[:args].last["args"].last["_aj_globalid"].split("/").last.to_i }.sort
    assert_equal [target_without_newer_sub.id,
                  target_without_newer_sub_by_user.id,
                  target_without_newer_sub_by_product.id,
                  target_without_newer_sub_by_time.id],
                 mailed_sub_ids
  end

  test "subscriptions_will_end_in_a_week" do
    assert_equal [], @bot.send(:subscriptions_for_will_end_in_a_week).map(&:id)

    target = create(:boutique_subscription, active_until: now + 1.week, recurrent: false)
    active = create(:boutique_subscription, active_until: now + 1.week, recurrent: true)
    too_old = create(:boutique_subscription, active_until: now + 1.week - 1.day, recurrent: false)
    too_fresh = create(:boutique_subscription, active_until: now + 1.week + 1.day, recurrent: false)

    assert_equal [target.id], @bot.send(:subscriptions_for_will_end_in_a_week).map(&:id)
  end

  private
    def now
      @now ||= Time.current.beginning_of_hour - 30.minutes
    end
end
