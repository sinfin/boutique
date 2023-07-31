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
