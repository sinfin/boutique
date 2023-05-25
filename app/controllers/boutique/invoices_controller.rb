# frozen_string_literal: true

class Boutique::InvoicesController < ApplicationController
  def show
    @order = Boutique::Order.with_invoice
                            .includes(line_items: { product_variant: :product })
                            .find_by_secret_hash!(params[:secret_hash])

    @public_page_title = @order.invoice_title

    render layout: "boutique/invoice"
  end
end
