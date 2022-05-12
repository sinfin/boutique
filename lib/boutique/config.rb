# frozen_string_literal: true

module Boutique
  class Config
    attr_accessor :using_cart,
                  :orders_edit_sidebar_shipping_content,

    def initialize
      # set defaults here
      @using_cart = true
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
