# frozen_string_literal: true

class Boutique::OrderMailer < Boutique::ApplicationMailer
  def paid(order)
    data = order_summary_data(order)

    email_template_mail(data, to: order.email)
  end

  def paid_subsequent(order)
    data = order_summary_data(order)

    email_template_mail(data, to: order.email)
  end

  private
    def order_summary_data(order)
      line_items = order.line_items.includes(product_variant: { product: :cover })

      {
        ORDER_NUMBER: order.number,
        ORDER_SUMMARY_HTML: render(partial: "summary_html", locals: { line_items:, total_price: order.total_price }),
        ORDER_SUMMARY_PLAIN: render(partial: "summary_plain", locals: { line_items:, total_price: order.total_price }),
      }
    end
end
