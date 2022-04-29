# frozen_string_literal: true

module Boutique
  class Engine < ::Rails::Engine
    isolate_namespace Boutique

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
    end
  end
end
