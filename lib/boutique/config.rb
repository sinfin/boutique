# frozen_string_literal: true

module Boutique
  class Config
    attr_accessor :logo_path,
                  :products_belong_to_site,
                  :parent_controller,
                  :after_order_paid_user_url_name,
                  :invoice_number_base_length,
                  :invoice_number_with_year_prefix,
                  :invoice_number_resets_each_year,
                  :mailers_bcc,
                  :mailers_reply_to,
                  :folio_console_collection_includes_for_orders,
                  :folio_console_collection_includes_for_products,
                  :folio_console_additional_filters_for_orders,
                  :orders_edit_recurrency_title_proc

    def initialize
      # set defaults here
      @logo_path = nil
      @products_belong_to_site = false
      @parent_controller = "ApplicationController"
      @after_order_paid_user_url_name = :root_url
      @invoice_number_base_length = 5
      @invoice_number_with_year_prefix = true
      @invoice_number_resets_each_year = true
      @mailers_bcc = nil
      @mailers_reply_to = nil
      @folio_console_collection_includes_for_orders = [line_items: { product_variant: :product }]
      @folio_console_collection_includes_for_products = [cover_placement: :file]
      @folio_console_additional_filters_for_orders = {}
      @orders_edit_recurrency_title_proc = -> (context:, current_site:, period:, price:, product:) do
        current_site.recurring_payment_disclaimer
                    .to_s
                    .gsub("{AMOUNT}", price.to_s)
                    .gsub("{PERIOD}", period)
      end
    end
  end

  def self.config
    @config ||= Boutique::Config.new
  end

  def self.configure
    yield(config)
  end
end
