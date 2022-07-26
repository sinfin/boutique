# frozen_string_literal: true

class Boutique::OrderMailer < Boutique::ApplicationMailer
  def paid(order)
    data = order_data(order)
    email_template_mail(data, to: order.email)
  end

  alias_method :paid_subsequent, :paid

  def unpaid_reminder(order)
    data = order_data(order)
    email_template_mail(data, to: order.email)
  end

  private
    def order_data(order)
      {
        ORDER_NUMBER: order.number,
        ORDER_SUMMARY_HTML: render(partial: "summary_html", locals: { order: }),
        ORDER_SUMMARY_PLAIN: render(partial: "summary_plain", locals: { order: }),
        ORDER_URL: boutique.order_url(order.secret_hash),
      }
    end
end
