# frozen_string_literal: true

class Boutique::OrderRefundMailer < Boutique::ApplicationMailer
  include ActionView::Helpers::NumberHelper

  def payout_by_paypal(order_refund)
    data = {
      ORDER_REFUND_TITLE: order_refund.to_label,
      ORDER_REFUND_URL: folio.console_order_refund_url(order_refund),
      USER_EMAIL: order_refund.email,
      ORDER_REFUND_REASON: order_refund.reason,
      PAID_AT: I18n.l(order_refund.paid_at, format: :short),
      TOTAL_PRICE_WITH_CURRENCY: number_to_currency(order_refund.total_price,
                                                    unit: order_refund.currency_unit,
                                                    precision: 2,
                                                    delimiter: " ")
    }
    site = find_site(order_refund)

    email_template_mail(data,
                        to: site.system_email,
                        site:)
  end

  def payout_by_voucher(order_refund)
    data = {
      ORDER_REFUND_TITLE: order_refund.to_label,
      ORDER_REFUND_URL: folio.console_order_refund_url(order_refund),
      USER_EMAIL: order_refund.email,
      ORDER_REFUND_REASON: order_refund.reason,
      PAID_AT: I18n.l(order_refund.paid_at, format: :short),
      TOTAL_PRICE_WITH_CURRENCY: number_to_currency(order_refund.total_price,
                                                    unit: order_refund.currency_unit,
                                                    precision: 2,
                                                    delimiter: " ")
    }
    site = find_site(order_refund)

    email_template_mail(data,
                        to: site.system_email,
                        site:)
  end

  private
    def find_site(order_refund)
      order_refund.site || Folio::Site.find_by(locale: "cs")
    end
end
