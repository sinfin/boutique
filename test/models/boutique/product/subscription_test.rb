# frozen_string_literal: true

require "test_helper"

class Boutique::Product::SubscriptionTest < ActiveSupport::TestCase
  setup do
    @subscription = create(:boutique_product_subscription)
  end

  test "issue_at" do
    date = Date.new(2022, 8, 8)

    @subscription.subscription_frequency = "monthly"
    issue = @subscription.issue_at(date)
    assert_equal 8, issue[:number]
    assert_equal 8, issue[:month]
    assert_equal 2022, issue[:year]

    @subscription.subscription_frequency = "bimonthly"
    issue = @subscription.issue_at(date)
    assert_equal 4, issue[:number]
    assert_equal 7, issue[:month]
    assert_equal 2022, issue[:year]

    @subscription.subscription_frequency = "quarterly"
    issue = @subscription.issue_at(date)
    assert_equal 3, issue[:number]
    assert_equal 7, issue[:month]
    assert_equal 2022, issue[:year]

    @subscription.subscription_frequency = "yearly"
    issue = @subscription.issue_at(date)
    assert_equal 1, issue[:number]
    assert_equal 1, issue[:month]
    assert_equal 2022, issue[:year]
  end

  test "SUBSCRIPTION_FREQUENCIES includes yearly with 12 months per issue" do
    assert_equal 12, Boutique::Product::Subscription::SUBSCRIPTION_FREQUENCIES[:yearly]
  end

  test "subscription_frequency: yearly is a valid value" do
    @subscription.subscription_frequency = "yearly"
    @subscription.valid?
    assert_not_includes @subscription.errors[:subscription_frequency].to_s, "is not included in the list"
  end

  test "subscription_frequency_in_months_per_issue returns 12 for yearly" do
    @subscription.subscription_frequency = "yearly"
    assert_equal 12, @subscription.subscription_frequency_in_months_per_issue
  end

  test "subscription_frequency_in_issues_per_year returns 1 for yearly" do
    @subscription.subscription_frequency = "yearly"
    assert_equal 1, @subscription.subscription_frequency_in_issues_per_year
  end
end
