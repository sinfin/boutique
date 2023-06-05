# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class Boutique::SubscriptionMailerPreview < ActionMailer::Preview
  def ended
    subscription = Boutique::Subscription.inactive.last

    Boutique::SubscriptionMailer.ended(subscription)
  end

  def failure
    subscription = Boutique::Subscription.last

    Boutique::SubscriptionMailer.failure(subscription)
  end

  def will_end_in_a_week
    subscription = Boutique::Subscription.last

    Boutique::SubscriptionMailer.will_end_in_a_week(subscription)
  end

  def unpaid
    subscription = Boutique::Subscription.last

    Boutique::SubscriptionMailer.unpaid(subscription)
  end
end
