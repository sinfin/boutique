# frozen_string_literal: true

class Boutique::MailerBot
  def initialize
  end

  def self.perform_all
    new.all
  end

  def all
    orders_unpaid_reminder
    subscriptions_will_be_paid_in_a_week
    subscriptions_failure
    subscriptions_unpaid
  end

  def orders_unpaid_reminder
    orders_for_unpaid_reminder.each do |order|
      Boutique::OrderMailer.unpaid_reminder(order).deliver_later
    end
  end

  def subscriptions_will_be_paid_in_a_week
    subscriptions_for_will_be_paid_in_a_week.each do |subscription|
      Boutique::SubscriptionMailer.will_be_paid_in_a_week(subscription).deliver_later
    end
  end

  def subscriptions_failure
    subscriptions_for_failure.each do |subscription|
      Boutique::SubscriptionMailer.failure(subscription).deliver_later
    end
  end

  def subscriptions_unpaid
    subscriptions_for_unpaid.each do |subscription|
      Boutique::SubscriptionMailer.unpaid(subscription).deliver_later
    end
  end

  private
    def now
      @now ||= Time.current.beginning_of_hour
    end

    def orders_for_unpaid_reminder
      Boutique::Order.confirmed
                     .where(confirmed_at: (now - 1.day - 1.hour)..(now - 1.day))
                     .except_subsequent
    end

    def subscriptions_for_will_be_paid_in_a_week
      Boutique::Subscription.where(active_until: (now + 1.week - 1.hour)..(now + 1.week),
                                   cancelled_at: nil)
    end

    def subscriptions_for_failure
      Boutique::Subscription.where(active_until: (now - 1.day - 1.hour)..(now - 1.day),
                                   cancelled_at: nil)
    end

    def subscriptions_for_unpaid
      Boutique::Subscription.where(active_until: (now - 15.days - 1.hour)..(now - 15.days),
                                   cancelled_at: nil)
    end
end
