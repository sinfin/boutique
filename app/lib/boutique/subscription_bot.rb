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
      else
        create_and_confirm_new_order!(subscription)
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
                            .recurring
                            .where(active_until:)
    end

    def now
      @now ||= Time.current.beginning_of_hour
    end

    def create_and_confirm_new_order!(subscription)
      subscription.transaction do
        if subscription.original_order.present?
          new_order = build_order_from_original_order(subscription)
        elsif subscription.recurrent_payments_init_id.present?
          new_order = build_order_from_subscription(subscription)
        else
          raise "I do not know how to build order for subscription #{subscription.to_json}"
        end

        begin
          new_order.confirm!
        rescue => error
          # report error but continue
          ::Raven.capture_exception(error, extra: { subscription_id: subscription.id })
        end
      end
    end

    def build_order_from_original_order(subscription)
      original_order = subscription.original_order
      new_order = subscription.orders.build(original_order.attributes.slice(*%w[folio_user_id
                                                                              first_name
                                                                              last_name
                                                                              email
                                                                              use_secondary_address
                                                                              ]))
      # TODO: update product prices if needed
      new_order.line_items = original_order.line_items.map(&:dup)
      new_order.subscription_line_item.subscription_starts_at = subscription.active_until
      new_order.primary_address = original_order.primary_address.dup
      new_order.secondary_address = original_order.secondary_address.dup
      new_order.original_payment = subscription.payment
      new_order
    end

    def build_order_from_subscription(subscription)
      user = subscription.user
      new_order = subscription.orders.build(folio_user_id: user.id,
                                            first_name: user.first_name,
                                            last_name: user.last_name,
                                            email: user.email,
                                            use_secondary_address: false)
      new_order.line_items.build(product_variant: subscription.product_variant,
                                 amount: 1,
                                 subscription_recurring: true,
                                 subscription_starts_at: subscription.active_until,
                                 subscription_period: subscription.period)
      new_order.site = subscription.product.site
      new_order.primary_address = user.primary_address.dup unless new_order.digital_only?
      new_order.secondary_address = user.secondary_address.dup
      new_order.save!

      new_order.original_payment = new_order.payments.create!(remote_id: subscription.recurrent_payments_init_id,
                                                            aasm_state: "paid",
                                                            amount: new_order.total_price,
                                                            payment_method: "fake_init_payment",
                                                            paid_at: subscription.active_from,
                                                            payment_gateway_provider: "import")
      subscription.update(payment: new_order.original_payment) if subscription.payment.nil?

      new_order
    end
end
