# frozen_string_literal: true

class Folio::Console::Boutique::ProductsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Product"

  private
    def product_params
      params.require(:product)
            .permit(*(@klass.column_names - ["id"]),
                    *file_placements_strong_params,
                    variants_attributes: product_variants_strong_params)
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      [cover_placement: :file]
    end

    def product_variants_strong_params
      Boutique::ProductVariant.column_names - ["boutique_product_id"] + %w[_destroy] + file_placements_strong_params
    end
end
