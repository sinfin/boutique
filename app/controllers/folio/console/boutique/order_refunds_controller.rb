class Folio::Console::Boutique::OrderRefundsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::OrderRefund"

  private

    def order_refund_params
      params.require(:boutique_order_refund)
            .permit(*(@klass.column_names - %w[id site_id]))
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      []
    end
end
