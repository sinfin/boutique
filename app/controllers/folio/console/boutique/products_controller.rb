# frozen_string_literal: true

class Folio::Console::Boutique::ProductsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Product"

  def basic
    @products = @products.where(type: "Boutique::Product::Basic")
    index
  end

  def subscription
    @products = @products.where(type: "Boutique::Product::Subscription")
    index
  end

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

    def product_variants_strong_params
      Boutique::ProductVariant.column_names - ["boutique_product_id"] + %w[_destroy] + file_placements_strong_params
    end

    def folio_console_collection_includes
      Boutique.config.folio_console_collection_includes_for_products
    end

    def index_tabs
      [
        {
          label: t("folio.console.boutique.products.index.tabs.all"),
          href: url_for([:console, @klass]),
          force_active: action_name == "index",
        },
        {
          label: t("folio.console.boutique.products.index.tabs.basic"),
          href: url_for([:basic, :console, @klass]),
          force_active: action_name == "basic",
        },
        {
          label: t("folio.console.boutique.products.index.tabs.subscription"),
          href: url_for([:subscription, :console, @klass]),
          force_active: action_name == "subscription",
        },
      ]
    end
end
