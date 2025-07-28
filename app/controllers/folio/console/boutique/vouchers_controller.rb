# frozen_string_literal: true

class Folio::Console::Boutique::VouchersController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Voucher", csv: true

  def create
    @voucher = @klass.create(folio_console_params_with_site)

    if @voucher.persisted? && @voucher.quantity > 1
      respond_with @voucher, location: url_for([:console, @klass]),
                             notice: t(".success_multiple", count: @voucher.quantity)
    else
      respond_with @voucher, location: respond_with_location
    end
  end

  private
    def voucher_params
      params.require(:voucher)
            .permit(*(@klass.column_names - ["id"]),
                    :code_type,
                    :quantity)
    end

    def index_filters
      {
        by_published: [true, false],
        by_product_code: Boutique::Product.all.map { |c| [c.to_console_label, c.code] }.sort_by { |c| c.first },
      }
    end

    def folio_console_collection_includes
      []
    end
end
