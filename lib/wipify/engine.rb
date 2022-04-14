# frozen_string_literal: true

module Wipify
  class Engine < ::Rails::Engine
    isolate_namespace Wipify

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
    end
  end
end
