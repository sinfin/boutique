# frozen_string_literal: true

class Boutique::SubscriptionMailer < Boutique::ApplicationMailer
  def will_be_paid_in_a_week(subscription)
    email_template_mail({}, to: subscription.user.email)
  end

  def failure(subscription)
    order = subscription.current_order
    data = {
      ORDER_URL: boutique.order_url(order.secret_hash),
    }
    email_template_mail(data, to: subscription.user.email)
  end

  def unpaid(subscription)
    email_template_mail({}, to: subscription.user.email)
  end
end
