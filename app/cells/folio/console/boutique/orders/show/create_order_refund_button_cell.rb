# frozen_string_literal: true

class Folio::Console::Boutique::Orders::Show::CreateOrderRefundButtonCell < Folio::ConsoleCell
  def button
    label = [
      content_tag(:i, nil, class: "fa fa-undo"),
      # spravně má být neco jako: image_tag("folio/arrow_u_left_top.svg", class: "f-c-b-orders-show__refund-img"),
      t(".label")
    ].join

    link_to(label,
            url,
            class: "btn btn-secondary f-c-index-header__btn")
  end

  def url
    url_for(action: :new, controller: "console/boutique/order_refunds", params: { order_id: model.id })

    # url_for([:new, :console, Boutique::OrderRefund, { order_id: model.id }])
    # folio.new_console_order_refund_url(order_id: model.id)
  end
end
