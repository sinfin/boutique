# frozen_string_literal: true

class Folio::Console::Boutique::ShippingMethodsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::ShippingMethod"

  private
    def shipping_method_params
      params.require(:shipping_method)
            .permit(*(@klass.column_names - ["id"]))
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      []
    end
end
