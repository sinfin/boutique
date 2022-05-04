# frozen_string_literal: true

module Boutique
  class Engine < ::Rails::Engine
    isolate_namespace Boutique

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
    end

    initializer :append_boutique_assets_paths do |app|
      app.config.assets.paths << self.root.join("app/cells")
    end

    initializer :append_boutique_migrations do |app|
      unless app.root.to_s.include? root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
