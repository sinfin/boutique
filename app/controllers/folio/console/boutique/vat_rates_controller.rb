# frozen_string_literal: true

class Folio::Console::Boutique::VatRatesController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::VatRate"

  private
    def vat_rate_params
      params.require(:vat_rate)
            .permit(*(@klass.column_names - ["id"]))
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      []
    end
end
