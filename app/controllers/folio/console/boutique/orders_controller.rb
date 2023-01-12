# frozen_string_literal: true

class Folio::Console::Boutique::OrdersController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Order", csv: true

  def index
    @orders = @orders.ordered

    case params[:tab]
    when nil
      @orders = @orders.where(aasm_state: %w[confirmed waiting_for_offline_payment])
    when "paid"
      @orders = @orders.where(aasm_state: "paid")
    when "dispatched"
      @orders = @orders.where(aasm_state: "dispatched")
    when "cancelled"
      @orders = @orders.where(aasm_state: "cancelled")
    end

    @orders_scope = @orders

    respond_with(@orders) do |format|
      format.html do
        @pagy, @orders = pagy(@orders)
        render "folio/console/boutique/orders/index"
      end
      format.csv do
        render_csv(@orders)
      end
    end
  end

  def invoices
    # TODO: apply filters
    @orders = @orders.where(aasm_state: %w[paid dispatched])
                     .order(invoice_number: :asc)

    data = ::CSV.generate(headers: true, col_sep: ",") do |csv|
      csv << %i[invoice_number paid_at email total_price].map do |a|
        Boutique::Order.human_attribute_name(a)
      end

      @orders.each do |order|
        csv << [
          order.invoice_number,
          l(order.paid_at, format: :as_date),
          order.email,
          order.total_price
        ]
      end
    end

    filename = "#{t(".filename")}-#{Date.today}".parameterize + ".csv"
    send_data data, filename:
  end

  private
    def order_params
      params.require(:order)
            .permit(*(@klass.column_names - ["id"]))
    end

    def index_tabs
      base_hash = {}

      index_filters_keys.each do |key|
        if params[key].present?
          base_hash[key] = params[key]
        end
      end

      tab = params[:tab]

      ["all", nil, "paid", "dispatched", "cancelled"].map do |tab_param|
        {
          force_href: url_for([:console, @klass, base_hash.merge(tab: tab_param)]),
          force_active: tab_param == tab,
          label: t(".tabs.#{tab_param || "index"}")
        }
      end
    end

    def index_filters
      @index_filters ||= {
        tab: {
          as: :hidden,
        },
        by_subscription_state: {
          as: :collection,
          collection: [
            [@klass.human_attribute_name("subscription_state/active"), "active"],
            [@klass.human_attribute_name("subscription_state/inactive"), "inactive"],
            [@klass.human_attribute_name("subscription_state/none"), "none"],
          ],
          width: 210,
        },
        by_subsequent_subscription: {
          as: :collection,
          collection: [
            [@klass.human_attribute_name("subsequent_subscription/new"), "new"],
            [@klass.human_attribute_name("subsequent_subscription/subsequent"), "subsequent"],
          ],
          width: 220,
        }
      }.merge(Boutique.config.folio_console_additional_filters_for_orders).merge(
        by_confirmed_at_range: {
          as: :date_range,
        },
        by_product_id: {
          klass: "Boutique::Product",
          width: 210,
        },
        by_number_range: {
          as: :numeric_range,
          autocomplete_attribute: :number,
          order_scope: :ordered,
          collapsed: true,
        },
        by_line_items_price_range: {
          as: :numeric_range,
          autocomplete_attribute: :line_items_price,
          order_scope: :ordered_by_line_items_price_asc,
          collapsed: true,
        },
        by_voucher_title: {
          as: :text,
          autocomplete_attribute: :title,
          autocomplete_klass: Boutique::Voucher,
          collapsed: true,
        },
        by_primary_address_country_code: {
          as: :collection,
          collection: [
            [@klass.human_attribute_name("primary_address_country_code/CZ"), "CZ"],
            [@klass.human_attribute_name("primary_address_country_code/SK"), "SK"],
            [@klass.human_attribute_name("primary_address_country_code/other"), "other"],
          ],
          collapsed: true,
        },
        by_non_pending_order_count_range: {
          as: :numeric_range,
          collapsed: true,
        }
      )
    end

    def folio_console_collection_includes
      Boutique.config.folio_console_collection_includes_for_orders
    end
end
