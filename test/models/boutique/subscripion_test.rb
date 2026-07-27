# frozen_string_literal: true

require "test_helper"

class Boutique::SubscripionTest < ActiveSupport::TestCase
  test "active" do
    assert_equal [], Boutique::Subscription.active.ids

    yet_not_active = create(:boutique_subscription, active_from: 1.month.from_now)
    active = create(:boutique_subscription, active_until: 1.month.from_now)
    expired = create(:boutique_subscription, active_until: 1.day.ago)

    assert_equal [active.id].sort, Boutique::Subscription.active.ids.sort
    assert_not yet_not_active.active?
    assert active.active?
    assert_not expired.active?
  end

  test "intro_until and price_for_next_period without an introductory price" do
    subscription = create(:boutique_subscription)

    assert_nil subscription.intro_until
    assert_not subscription.intro_active?
    assert_nil subscription.price_for_next_period
  end

  test "discounted introductory price is charged for every introductory period" do
    subscription = intro_subscription(intro_price: 49, intro_duration_months: 3)

    # a discounted introductory price does not change the length of the first
    # period, it only changes what is charged
    assert_equal subscription.active_from + 1.month, subscription.active_until
    assert_equal subscription.active_from + 3.months, subscription.intro_until
    assert subscription.intro_active?

    # periods starting before intro_until are still introductory
    assert_equal 49, subscription.price_for_next_period

    subscription.active_until = subscription.active_from + 2.months
    assert_equal 49, subscription.price_for_next_period

    # the period starting exactly at intro_until is already a regular one
    subscription.active_until = subscription.intro_until
    assert_equal 149, subscription.price_for_next_period

    subscription.active_until = subscription.active_from + 4.months
    assert_equal 149, subscription.price_for_next_period
  end

  test "free trial is active for the whole introductory block" do
    subscription = intro_subscription(intro_price: 0, intro_duration_months: 2)

    assert_equal subscription.active_from + 2.months, subscription.active_until
    assert_equal subscription.active_until, subscription.intro_until

    # nothing is charged inside the block, the first charge is a regular one
    assert_equal 149, subscription.price_for_next_period
  end

  test "price_for_next_period ignores later product changes" do
    subscription = intro_subscription(intro_price: 49, intro_duration_months: 3)

    subscription.product_variant.product.update!(regular_price: 199)
    subscription.active_until = subscription.intro_until

    assert_equal 149, subscription.price_for_next_period
  end

  private
    def setup_emails
      site = create(:folio_site)
      Rails.application.load_tasks
      Rake::Task["folio:email_templates:idp_seed"].execute

      Rails.application.routes.default_url_options[:host] = site.domain
      Rails.application.routes.default_url_options[:only_path] = false
    end

    def intro_subscription(intro_price:, intro_duration_months:)
      setup_emails

      product = create(:boutique_product_subscription,
                       regular_price: 149,
                       subscription_period: 1,
                       intro_enabled: true,
                       intro_price:,
                       intro_duration_months:)

      order = create(:boutique_order, :ready_to_be_confirmed, :with_user, line_items_count: 0)
      order.line_items << build(:boutique_line_item, product:, order:)
      order.save!

      assert order.confirm!, order.errors.full_messages.to_sentence
      order.pay!

      order.subscription.reload
    end
end
