# frozen_string_literal: true

class Boutique::MailerBot
  def initialize
  end

  def self.perform_all
    new.all
  end

  def all
    orders_unpaid_reminder
    subscriptions_ended
    subscriptions_failed_payment
    subscriptions_unpaid
    subscriptions_expiring_soon
    # subscriptions_will_end_in_a_week
  end

  def orders_unpaid_reminder
    orders_for_unpaid_reminder.each do |order|
      Boutique::OrderMailer.unpaid_reminder(order).deliver_later
    end
  end

  def subscriptions_ended
    subscriptions_for_ended.each do |subscription|
      Boutique::SubscriptionMailer.ended(subscription).deliver_later
    end
  end

  def subscriptions_failed_payment
    subscriptions_for_failed_payment.each do |subscription|
      Boutique::SubscriptionMailer.failed_payment(subscription).deliver_later
    end
  end

  def subscriptions_unpaid
    subscriptions_for_unpaid.each do |subscription|
      next if subscription.user.subscriptions
                               .where("? < active_until", now)
                               .where(boutique_product_variant_id: subscription.boutique_product_variant_id)
                               .exists?
      Boutique::SubscriptionMailer.unpaid(subscription).deliver_later
    end
  end

  def subscriptions_will_end_in_a_week
    subscriptions_for_will_end_in_a_week.each do |subscription|
      Boutique::SubscriptionMailer.will_end_in_a_week(subscription).deliver_later
    end
  end

  def subscriptions_expiring_soon
    subscriptions_for_expiring_soon.each do |subscription|
      Boutique::SubscriptionMailer.expiring_soon(subscription).deliver_later
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

    def subscriptions_for_ended
      Boutique::Subscription.non_recurring
                            .where(active_until: (now - 1.day - 1.hour)..(now - 1.day))
    end

    def subscriptions_for_failed_payment
      Boutique::Subscription.recurring
                            .where(active_until: (now - 12.hours - 1.hour)..(now - 12.hours))
    end

    def subscriptions_for_unpaid
      Boutique::Subscription.recurring
                            .where(active_until: (now - 7.days)..(now - 7.days + 1.hour))
    end

    def subscriptions_for_will_end_in_a_week
      Boutique::Subscription.non_recurring
                            .where(active_until: (now + 1.week - 1.hour)..(now + 1.week))
    end

    def subscriptions_for_expiring_soon
      # sends email just once a day
      Boutique::Subscription.recurring
                            .where("payment_expiration_date::timestamp BETWEEN ? AND ?",
                                   now + 1.week - 7.hour,
                                   now + 1.week - 6.hours)
    end
end
