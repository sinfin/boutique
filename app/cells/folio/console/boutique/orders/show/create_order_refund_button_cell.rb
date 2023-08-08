# frozen_string_literal: true

class Folio::Console::Boutique::Orders::Show::CreateOrderRefundButtonCell < Folio::ConsoleCell
  def show
    render if model.paid_at.present?
  end

  def url
    url_for(action: :new, controller: "console/boutique/order_refunds", params: { order_id: model.id })

    # url_for([:new, :console, Boutique::OrderRefund, { order_id: model.id }])
    # folio.new_console_order_refund_url(order_id: model.id)
  end
end
