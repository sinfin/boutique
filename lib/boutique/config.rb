# frozen_string_literal: true

module Boutique
  class Config
    attr_accessor :use_cart_in_order,
                  :orders_edit_sidebar_shipping_content,

    def initialize
      # set defaults here
      @use_cart_in_order = true
      @orders_edit_sidebar_shipping_content = nil
    end
  end

  def self.config
    @config ||= Boutique::Config.new
  end

  def self.configure
    yield(config)
  end
end
