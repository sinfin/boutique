# frozen_string_literal: true

class Boutique::SubscriptionBot
  def initialize
  end

  def self.charge_all_eligible
    new.charge_all_eligible
  end

  def charge_all_eligible
    charge(subscriptions_eligible_for_recurrent_payment_all)
  end

  def charge(scope)
    scope.find_each do |subscription|
      if subscription.current_order.present? && subscription.current_order.confirmed?
        subscription.current_order.charge_recurrent_payment!
        next
      end

      subscription.transaction do
        original_order = subscription.original_order
        new_order = subscription.orders.build(original_order.attributes.slice(*%w[folio_user_id
                                                                                  first_name
                                                                                  last_name
                                                                                  email
                                                                                  use_secondary_address]))

        new_order.line_items = original_order.line_items.map do |original_line_item|
          line_item = original_line_item.dup
          line_item.vat_rate_value = nil
          line_item.subscription_starts_at += line_item.subscription_period.months if line_item.subscription_starts_at?
          line_item
        end

        new_order.primary_address = original_order.primary_address.dup
        new_order.secondary_address = original_order.secondary_address.dup
        new_order.original_payment = subscription.payment

        begin
          new_order.confirm!
        rescue => error
          # report error but continue
          Raven.capture_exception(error, extra: { subscription_id: subscription.id })
        end
      end
    end
  end

  private
    def subscriptions_eligible_for_recurrent_payment_all
      subscriptions_eligible_for_recurrent_payment_first_try
        .or(subscriptions_eligible_for_recurrent_payment_second_try)
        .or(subscriptions_eligible_for_recurrent_payment_third_try)
        .or(subscriptions_eligible_for_recurrent_payment_fourth_try)
    end

    def subscriptions_eligible_for_recurrent_payment_first_try
      subscriptions_eligible_for_recurrent_payment
    end

    def subscriptions_eligible_for_recurrent_payment_second_try
      subscriptions_eligible_for_recurrent_payment(repeated_attempt: 1)
    end

    def subscriptions_eligible_for_recurrent_payment_third_try
      subscriptions_eligible_for_recurrent_payment(repeated_attempt: 2)
    end

    def subscriptions_eligible_for_recurrent_payment_fourth_try
      subscriptions_eligible_for_recurrent_payment(repeated_attempt: 3)
    end

    def subscriptions_eligible_for_recurrent_payment(repeated_attempt: 0)
      active_until = (now + 6.hours - repeated_attempt.day)..(now + 7.hours - repeated_attempt.day)

      Boutique::Subscription.includes(:orders, :payment)
                            .where(active_until:,
                                   cancelled_at: nil)
    end

    def now
      @now ||= Time.current.beginning_of_hour
    end
end
