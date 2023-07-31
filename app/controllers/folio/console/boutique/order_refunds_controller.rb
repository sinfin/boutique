# frozen_string_literal: true

class Folio::Console::Boutique::OrderRefundsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::OrderRefund", csv: true

  def new
    super

    folio_console_record.boutique_order_id = params[:order_id]
    folio_console_record.issue_date = Date.today
    folio_console_record.due_date = Date.today + 14.days
    folio_console_record.date_of_taxable_supply = Date.today
    folio_console_record.setup_subscription_refund(Date.today)
    folio_console_record.total_price_in_cents = -1 * folio_console_record.order.total_price_in_cents
    folio_console_record.payment_method = "VOUCHER"
  end

  def corrective_tax_documents
    data = ::CSV.generate(headers: true, col_sep: ",") do |csv|
      csv << %i[document_number order paid_at email total_price].map do |a|
        ::Boutique::OrderRefund.human_attribute_name(a)
      end

      @order_refunds.each do |order_refund|
        csv << [
          order_refund.document_number,
          order_refund.order.number,
          l(order_refund.paid_at, format: :as_date),
          order_refund.email,
          order_refund.total_price
        ]
      end
    end

    filename = "#{t(".filename")}-#{Date.today}".parameterize + ".csv"
    send_data data, filename:
  end

  def corrective_tax_document
    @order_refund = ::Boutique::OrderRefund.find(params[:id])
    # @public_page_title = @order_refnd.invoice_title
    @public_page_title = @order_refund.document_number

    render layout: "boutique/invoice"
  end

  private
    def order_refund_params
      params.require(:order_refund)
            .permit(*(@klass.column_names - %w[id site_id] + %w[total_price]))
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      []
    end
end
