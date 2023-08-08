# frozen_string_literal: true

class Boutique::DocumentsController < ApplicationController
  def invoice
    @order = Boutique::Order.with_invoice
                            .includes(line_items: { product_variant: :product })
                            .find_by_secret_hash!(params[:secret_hash])

    @public_page_title = @order.invoice_title

    render layout: "boutique/document"
  end

  def corrective_tax_document
    @order_refund = Boutique::OrderRefund.with_document
                            .includes(:order)
                            .find_by_secret_hash!(params[:secret_hash])

    @public_page_title = @order_refund.corrective_tax_document_title

    render layout: "boutique/document"
  end
end
