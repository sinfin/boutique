# frozen_string_literal: true

class Folio::Console::Boutique::ProductsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Product"

  def new
    @product.type = Boutique::Product::Basic
    @product.variants.build(master: true)
  end

  private
    def product_params
      params.require(:product)
            .permit(*(@klass.column_names - ["id"]),
                    *@klass.additional_params,
                    *file_placements_strong_params,
                    variants_attributes: product_variants_strong_params)
    end

    def index_filters
      {}
    end

    def product_variants_strong_params
      Boutique::ProductVariant.column_names - ["boutique_product_id"] + %w[_destroy]
    end

    def folio_console_collection_includes
      Boutique.config.folio_console_collection_includes_for_products
    end
end
