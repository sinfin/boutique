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
        by_number_query: {
          as: :text,
          autocomplete_attribute: :number,
        },
        by_full_name_query: {
          as: :text,
          autocomplete_attribute: :last_name,
        },
        by_addresses_query: {
          as: :text,
        },
        by_address_identification_number_query: {
          as: :text,
          autocomplete_attribute: :identification_number,
          autocomplete_klass: Folio::Address::Base,
        },
        by_email_query: {
          as: :text,
          autocomplete_attribute: :email,
        },
        by_confirmed_at_range: :date_range,
        by_subscription_state: [
          [@klass.human_attribute_name("subscription_state/active"), "active"],
          [@klass.human_attribute_name("subscription_state/inactive"), "inactive"],
          [@klass.human_attribute_name("subscription_state/none"), "none"],
        ],
        by_subsequent_subscription: [
          [@klass.human_attribute_name("subsequent_subscription/new"), "new"],
          [@klass.human_attribute_name("subsequent_subscription/subsequent"), "subsequent"],
        ],
      }
    end

    def folio_console_collection_includes
      []
    end
end
