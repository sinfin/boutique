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

  test "intro? is off unless enabled and fully configured" do
    assert_not @subscription.intro?
    assert_not @subscription.intro_free?

    @subscription.assign_attributes(intro_price: 49, intro_duration_months: 3)
    assert_not @subscription.intro?, "must stay off until intro_enabled is set"

    @subscription.intro_enabled = true
    assert @subscription.intro?
    assert_not @subscription.intro_free?
  end

  test "intro_free? for zero intro price" do
    @subscription.assign_attributes(intro_enabled: true,
                                    intro_price: 0,
                                    intro_duration_months: 2)

    assert @subscription.intro?
    assert @subscription.intro_free?
  end

  test "intro price and duration are required when enabled" do
    @subscription.intro_enabled = true

    assert_not @subscription.valid?
    assert @subscription.errors.of_kind?(:intro_price, :blank)
    assert @subscription.errors.of_kind?(:intro_duration_months, :blank)
  end

  test "intro price must be non negative and lower than regular price" do
    @subscription.assign_attributes(intro_enabled: true,
                                    intro_duration_months: 1,
                                    subscription_period: 1,
                                    regular_price: 99)

    @subscription.intro_price = -1
    assert_not @subscription.valid?
    assert @subscription.errors.of_kind?(:intro_price, :greater_than_or_equal_to)

    @subscription.intro_price = 99
    assert_not @subscription.valid?
    assert @subscription.errors.of_kind?(:intro_price, :less_than)

    @subscription.intro_price = 0
    assert @subscription.valid?, @subscription.errors.full_messages.to_sentence
  end

  test "intro duration must be at least one month" do
    @subscription.assign_attributes(intro_enabled: true,
                                    intro_price: 0,
                                    intro_duration_months: 0)

    assert_not @subscription.valid?
    assert @subscription.errors.of_kind?(:intro_duration_months, :greater_than_or_equal_to)
  end

  test "intro requires recurrent payment" do
    @subscription.assign_attributes(intro_enabled: true,
                                    intro_price: 0,
                                    intro_duration_months: 2,
                                    subscription_recurrent_payment_disabled: true)

    assert_not @subscription.valid?
    assert @subscription.errors.of_kind?(:intro_enabled, :requires_recurrent_payment)

    @subscription.subscription_recurrent_payment_disabled = false
    assert @subscription.valid?, @subscription.errors.full_messages.to_sentence
  end

  test "discounted intro duration must fit whole subscription periods" do
    @subscription.assign_attributes(intro_enabled: true,
                                    intro_price: 49,
                                    subscription_period: 3,
                                    intro_duration_months: 4)

    assert_not @subscription.valid?
    assert @subscription.errors.of_kind?(:intro_duration_months, :must_be_multiple_of_subscription_period)

    @subscription.intro_duration_months = 6
    assert @subscription.valid?, @subscription.errors.full_messages.to_sentence
  end

  test "free intro duration does not have to fit subscription periods" do
    # a free trial is charged just once, the subscription runs the whole introductory block
    @subscription.assign_attributes(intro_enabled: true,
                                    intro_price: 0,
                                    subscription_period: 3,
                                    intro_duration_months: 4)

    assert @subscription.valid?, @subscription.errors.full_messages.to_sentence
  end

  test "intro fields are ignored when disabled" do
    @subscription.assign_attributes(intro_enabled: false,
                                    intro_price: 999_999,
                                    subscription_period: 3,
                                    intro_duration_months: 4)

    assert @subscription.valid?, @subscription.errors.full_messages.to_sentence
    assert_not @subscription.intro?
  end
end
