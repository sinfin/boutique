# frozen_string_literal: true

require "aasm"

module Wipify
  class Engine < ::Rails::Engine
    isolate_namespace Wipify
  end
end
