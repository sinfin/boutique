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
    data = order_data(order, address: false)
    email_template_mail(data,
                        to: order.email,
                        site: order.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def unpaid_reminder(order)
    data = order_data(order, address: false)
    email_template_mail(data,
                        to: order.email,
                        site: order.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  def gift_notification(order, token = nil)
    data = order_data(order, gift_notification: true)
    data[:USER_ACCEPT_INVITATION_URL] = main_app.accept_user_invitation_url(invitation_token: token)
    email_template_mail(data,
                        to: order.gift_recipient_email,
                        site: order.site,
                        bcc: ::Boutique.config.mailers_bcc,
                        reply_to: ::Boutique.config.mailers_reply_to)
  end

  private
    def order_data(order, address: true, gift_notification: false)
      h = {
        ORDER_NUMBER: order.number,
        ORDER_SUMMARY_HTML: render(partial: "summary_html", locals: { order:, gift_notification: }),
        ORDER_SUMMARY_PLAIN: render(partial: "summary_plain", locals: { order:, gift_notification: }),
      }

      if address
        h[:ORDER_SHIPPING_ADDRESS_HTML] = order_shipping_address(order, html: true)
        h[:ORDER_SHIPPING_ADDRESS_PLAIN] = order_shipping_address(order)
      end

      unless gift_notification
        h[:ORDER_URL] = boutique.order_url(order.secret_hash)
      end

      h
    end

    def order_shipping_address(order, html: false)
      a = order.primary_address

      return order.full_name if a.nil?

      new_line = html ? "<br>" : "\n"

      [
        a.name || order.gift ? order.gift_recipient_full_name : order.full_name,
        [a.address_line_1, a.address_line_2].join(" "),
        [a.zip, a.city].join(" "),
        a.country_code,
        a.phone
      ].join(new_line)
    end
end
