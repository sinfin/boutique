# frozen_string_literal: true

class Boutique::OrderMailer < Boutique::ApplicationMailer
  def paid(order)
    data = order_data(order)
    email_template_mail(data,
                        to: order.email,
                        site: order.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def paid_subsequent(order)
    data = order_data(order)
    email_template_mail(data,
                        to: order.email,
                        site: order.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def dispatched(order)
    data = order_data(order)

    # TODO: add tracking
    data[:TRACKING_NUMBER] = "12345678"
    data[:TRACKING_URL] = "https://trackingcompany.com/12345678"

    email_template_mail(data,
                        to: order.email,
                        site: order.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def unpaid_reminder(order)
    data = order_data(order, summary: false)
    email_template_mail(data,
                        to: order.email,
                        site: order.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def gift_notification(order)
    data = order_data(order, gift_notification: true)
    email_template_mail(data,
                        to: order.gift_recipient_email,
                        site: order.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def gift_notification_with_invitation(order, token = nil)
    data = order_data(order, gift_notification: true)
    data[:USER_ACCEPT_INVITATION_URL] = main_app.accept_user_invitation_url(invitation_token: token)
    email_template_mail(data,
                        to: order.gift_recipient_email,
                        site: order.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  private
    def order_data(order, summary: true, gift_notification: false)
      h = {
        ORDER_NUMBER: order.number,
      }

      if summary
        h[:ORDER_SUMMARY_HTML] = render(partial: "summary_html", locals: { order:, gift_notification: })
        h[:ORDER_SUMMARY_PLAIN] = render(partial: "summary_plain", locals: { order:, gift_notification: })
      end

      unless gift_notification
        h[:ORDER_URL] = boutique.order_url(order.secret_hash)
      end

      h
    end
end
