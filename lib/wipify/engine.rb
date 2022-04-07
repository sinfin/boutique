# frozen_string_literal: true

require "aasm"
require "ar-sequence"

module Wipify
  class Engine < ::Rails::Engine
    isolate_namespace Wipify
  end
end
