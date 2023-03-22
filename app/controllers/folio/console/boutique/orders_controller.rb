# frozen_string_literal: true

class Folio::Console::Boutique::OrdersController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Order", csv: true

  before_action :filter_folio_console_collection, only: %i[index invoices]
  before_action :filter_orders_by_tab, only: %i[index invoices]
  before_action :filter_orders_with_invoices, only: %i[invoices]

  def index
    @orders = @orders.ordered
    @orders_scope = @orders

    respond_with(@orders) do |format|
      format.html do
        @pagy, @orders = pagy(@orders)
        render "folio/console/boutique/orders/index"
      end
      format.csv do
        @orders = @orders.includes(:primary_address, :secondary_address)
        render_csv(@orders)
      end
    end
  end

  def invoices
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
            .permit(*(@klass.column_names - ["id"]),
                    *addresses_strong_params)
    end

    def index_tabs
      base_hash = {}

      index_filters_keys.each do |key|
        if params[key].present?
          base_hash[key] = params[key]
        end
      end

      tab = params[:tab]

      [nil, "unpaid", "paid", "dispatched", "cancelled"].map do |tab_param|
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
        by_paid_at_range: {
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
        by_total_price_range: {
          as: :numeric_range,
          autocomplete_attribute: :total_price,
          order_scope: :ordered_by_total_price_asc,
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

    def filter_orders_by_tab
      case params[:tab]
      when nil
        @orders = @orders.except_pending
      when "unpaid"
        @orders = @orders.where(aasm_state: %w[confirmed waiting_for_offline_payment])
      when "paid"
        @orders = @orders.where(aasm_state: "paid")
      when "dispatched"
        @orders = @orders.where(aasm_state: "dispatched")
      when "cancelled"
        @orders = @orders.where(aasm_state: "cancelled")
      end
    end

    def filter_orders_with_invoices
      @orders = @orders.reorder(invoice_number: :asc)
                       .where.not(invoice_number: nil)
    end

    def folio_console_collection_includes
      Boutique.config.folio_console_collection_includes_for_orders
    end
end
