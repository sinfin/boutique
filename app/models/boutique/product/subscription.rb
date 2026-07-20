# frozen_string_literal: true

class Boutique::Product::Subscription < Boutique::Product
  SUBSCRIPTION_FREQUENCIES = {
    none: nil,
    monthly: 1,
    bimonthly: 2,
    quarterly: 3,
    yearly: 12,
  }

  validates :subscription_frequency, inclusion: { in: SUBSCRIPTION_FREQUENCIES.keys.map(&:to_s) }

  def subscription_recurrent_payment_enabled?
    !subscription_recurrent_payment_disabled?
  end

  def current_issue
    issue_at(Date.today)
  end

  def upcoming_issue
    issue_at(Date.today + subscription_frequency_in_months_per_issue.months)
  end

  def issue_at(date)
    return unless has_subscription_frequency?

    if subscription_frequency_in_months_per_issue == 1
      number = month = date.month
    else
      number = (date.month.to_f / subscription_frequency_in_months_per_issue).ceil
      month = (number - 1) * subscription_frequency_in_months_per_issue + 1
    end

    {
      number:,
      month:,
      year: date.year,
    }
  end

  def current_and_upcoming_issues(years = 1)
    return [] unless has_subscription_frequency?

    start = Date.today
    per_year = 12 / subscription_frequency_in_months_per_issue

    (years * per_year).times.map do |i|
      date = start + (i * subscription_frequency_in_months_per_issue).months
      issue_at(date)
    end
  end

  def subscription_frequency_in_months_per_issue
    return unless has_subscription_frequency?

    SUBSCRIPTION_FREQUENCIES[subscription_frequency.to_sym]
  end

  def subscription_frequency_in_issues_per_year
    return unless has_subscription_frequency?

    12 / subscription_frequency_in_months_per_issue
  end

  def has_subscription_frequency?
    subscription_frequency != "none"
  end

  def self.subscription_frequency_options_for_select
    SUBSCRIPTION_FREQUENCIES.keys.map do |value|
      [human_attribute_name("subscription_frequency/#{value}"), value]
    end
  end
end
