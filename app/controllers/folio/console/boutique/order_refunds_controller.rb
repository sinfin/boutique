# frozen_string_literal: true

class Folio::Console::Boutique::OrderRefundsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::OrderRefund", csv: true

  before_action :filter_order_refunds_by_tab, only: %i[index corrective_tax_documents]
  before_action :filter_orders_refunds_with_documents, only: %i[corrective_tax_documents]


  def index
    @order_refunds = @order_refunds.ordered
    @order_refunds_scope = @order_refunds

    respond_with(@order_refunds) do |format|
      format.html do
        @pagy, @order_refunds = pagy(@order_refunds)
        render "folio/console/boutique/order_refunds/index"
      end
      format.csv do
        @order_refunds = @order_refunds.includes(:primary_address, :secondary_address)
        render_csv(@order_refunds)
      end
    end
  end

  def new
    super

    folio_console_record.setup_from(Boutique::Order.find(params[:order_id]))
  end

  def show
  end

  def corrective_tax_documents
    data = ::CSV.generate(headers: true, col_sep: ",") do |csv|
      csv << %i[document_number order approved_at paid_at email total_price].map do |a|
        ::Boutique::OrderRefund.human_attribute_name(a)
      end

      @order_refunds.each do |order_refund|
        csv << [
          order_refund.to_label,
          order_refund.order.number,
          order_refund.approved_at.nil? ? "" : l(order_refund.approved_at, format: :as_date),
          order_refund.paid_at.nil? ? "" : l(order_refund.paid_at, format: :as_date),
          order_refund.email,
          view_context.number_with_precision(order_refund.total_price, precision: 2, delimiter: " ")
        ]
      end
    end

    filename = "#{t(".filename")}-#{Date.today}".parameterize + ".csv"
    send_data data, filename:
  end

  def corrective_tax_document
    @order_refund = ::Boutique::OrderRefund.find(params[:id])
    # @public_page_title = @order_refnd.invoice_title
    @public_page_title = @order_refund.document_number

    render layout: "boutique/invoice"
  end

  private
    def order_refund_params
      params.require(:order_refund)
            .permit(*(@klass.column_names - %w[id site_id] + %w[total_price subscriptions_price]))
    end

    def index_tabs
      base_hash = {}

      index_filters_keys.each do |key|
        if params[key].present?
          base_hash[key] = params[key]
        end
      end

      tab = params[:tab]

      [nil, "created", "approved", "paid", "cancelled"].map do |tab_param|
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
      }.merge(Boutique.config.folio_console_additional_filters_for_orders)
       .merge(
        by_product_type_keyword: [
          [I18n.t("folio.console.boutique.orders.index.filters.by_product_type_keyword/subscription"), "subscription"],
          [I18n.t("folio.console.boutique.orders.index.filters.by_product_type_keyword/basic"), "basic"],
        ],
        by_payment_method: {
          as: :collection,
          collection: Boutique::OrderRefund.payment_method_options,
          width: 220,
        },
        by_paid_at_range: {
          as: :date_range,
        },

      )
    end

    def filter_order_refunds_by_tab
      case params[:tab]
      when nil
        @order_refunds = @order_refunds
      when "created"
        @order_refunds = @order_refunds.created
      when "approved"
        @order_refunds = @order_refunds.approved_to_pay
      when "paid"
        @order_refunds = @order_refunds.paid
      when "cancelled"
        @order_refunds = @order_refunds.cancelled
      end
    end

    def filter_orders_refunds_with_documents
      @order_refunds = @order_refunds.reorder(document_number: :asc)
                       .where.not(document_number: nil)
    end

    def folio_console_collection_includes
      Boutique.config.folio_console_collection_includes_for_order_refunds
    end
end
