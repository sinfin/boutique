# frozen_string_literal: true

module Boutique
  class Config
    attr_accessor :use_cart_in_orders,
                  :logo_path,
                  :orders_edit_sidebar_shipping_content,
                  :products_belong_to_site,
                  :parent_controller,
                  :after_order_paid_user_url_name

    def initialize
      # set defaults here
      @use_cart_in_orders = true
      @logo_path = nil
      @orders_edit_sidebar_shipping_content = nil
      @products_belong_to_site = false
      @parent_controller = "ApplicationController"
      @after_order_paid_user_url_name = :root_url
    end
  end

  def self.config
    @config ||= Boutique::Config.new
  end

  def self.configure
    yield(config)
  end
end
