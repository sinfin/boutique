# frozen_string_literal: true

require "boutique/version"
require "boutique/engine"

require "aasm"
require "ar-sequence"
require "slim"

require "gopay"

module Boutique
  class << self
    attr_accessor :using_cart,
                  :data_protection_page_type,
                  :terms_page_type
  end

  def self.configure
    yield(self)
  end

  configure do |config|
    config.using_cart = true
    config.data_protection_page_type = nil
    config.terms_page_type = nil
  end
end
