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
        by_product_id: {
          klass: "Boutique::Product",
        },
        by_number_from: {
          as: :text,
          autocomplete_attribute: :number,
          order_scope: :ordered,
        },
        by_number_to: {
          as: :text,
          autocomplete_attribute: :number,
          order_scope: :ordered,
        },
        by_line_items_price_from: {
          as: :text,
          autocomplete_attribute: :line_items_price,
          order_scope: :ordered_by_line_items_price_asc,
        },
        by_line_items_price_to: {
          as: :text,
          autocomplete_attribute: :line_items_price,
          order_scope: :ordered_by_line_items_price_desc,
        },
        by_voucher_title: {
          as: :text,
          autocomplete_attribute: :title,
          autocomplete_klass: Boutique::Voucher,
        },
        by_primary_address_country_code: [
          [@klass.human_attribute_name("primary_address_country_code/CZ"), "CZ"],
          [@klass.human_attribute_name("primary_address_country_code/SK"), "SK"],
          [@klass.human_attribute_name("primary_address_country_code/other"), "other"],
        ],
        by_non_pending_order_count_from: {
          as: :text,
        },
        by_non_pending_order_count_to: {
          as: :text,
        },
      }
    end

    def folio_console_collection_includes
      Boutique.config.folio_console_collection_includes_for_orders
    end
end
