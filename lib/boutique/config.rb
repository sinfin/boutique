# frozen_string_literal: true

module Boutique
  class Config
    attr_accessor :use_cart_in_orders,
                  :orders_edit_sidebar_shipping_content,
                  :parent_controller

    def initialize
      # set defaults here
      @use_cart_in_orders = true
      @orders_edit_sidebar_shipping_content = nil
      @parent_controller = "ApplicationController"
    end
  end

  def self.config
    @config ||= Boutique::Config.new
  end

  def self.configure
    yield(config)
  end
end
