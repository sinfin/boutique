# frozen_string_literal: true

class Boutique::SubscriptionMailer < Boutique::ApplicationMailer
  def ended(subscription)
    email_template_mail({},
                        to: subscription.user.email,
                        site: subscription.product_variant.product.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def failed_payment(subscription)
    order = subscription.current_order
    data = {
      ORDER_URL: boutique.order_url(order.secret_hash),
    }

    email_template_mail(data,
                        to: subscription.payer.email,
                        site: subscription.product_variant.product.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def will_end_in_a_week(subscription)
    email_template_mail({},
                        to: subscription.user.email,
                        site: subscription.product_variant.product.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def unpaid(subscription)
    email_template_mail({},
                        to: subscription.payer.email,
                        site: subscription.product_variant.product.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end
end
