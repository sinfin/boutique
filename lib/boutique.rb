# frozen_string_literal: true

require "boutique/version"
require "boutique/engine"

require "aasm"
require "ar-sequence"
require "slim"

module Boutique
  class << self
    attr_accessor :using_cart
  end

  def self.configure
    yield(self)
  end

  configure do |config|
    config.using_cart = true
  end
end
