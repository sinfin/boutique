# frozen_string_literal: true

class Folio::Console::Boutique::OrderRefundsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::OrderRefund", csv: true

  def new
    super
    folio_console_record.boutique_order_id = params[:order_id]
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
