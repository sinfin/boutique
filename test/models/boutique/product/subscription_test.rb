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
  end
end
