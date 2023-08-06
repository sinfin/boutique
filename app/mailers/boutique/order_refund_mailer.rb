# frozen_string_literal: true

class Boutique::OrderRefundMailer < Boutique::ApplicationMailer
  def payout_by_paypal(order_refund)
    # data = order_data(order)
    # email_template_mail(data,
    #                     to: order.email,
    #                     site: order.site,
    #                     bcc: ::Boutique.config.mailers_bcc,
    #                     reply_to: ::Boutique.config.mailers_reply_to)
  end

  def payout_by_voucher(order_refund)
    # data = order_data(order)
    # email_template_mail(data,
    #                     to: order.email,
    #                     site: order.site,
    #                     bcc: ::Boutique.config.mailers_bcc,
    #                     reply_to: ::Boutique.config.mailers_reply_to)
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

      email_template_data_defaults(order).merge(h)
    end
end
