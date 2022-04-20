# frozen_string_literal: true

class Folio::Console::Boutique::OrdersController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Order"

  def index
    @orders_scope = @orders.ordered
    @orders_scope = @orders_scope.except_pending unless filter_params[:by_state] == "pending"

    @pagy, @orders = pagy(@orders_scope)
  end

  private
    def order_params
      params.require(:order)
            .permit(*(@klass.column_names - ["id"]))
    end

    def index_filters
      {
        by_state: @klass.aasm.states_for_select,
      }
    end

    def folio_console_collection_includes
      [
        :shipping_method,
        :payment_method,
      ]
    end
end
