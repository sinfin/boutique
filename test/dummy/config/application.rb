# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require "folio"
require "boutique"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false

    Rails.autoloaders.main.ignore("#{::Folio::Engine.root}/app/lib/folio/console/simple_form_components")
    Rails.autoloaders.main.ignore("#{::Folio::Engine.root}/app/lib/folio/console/simple_form_inputs")

    overrides = [
      Folio::Engine.root.join("app/overrides").to_s,
      Boutique::Engine.root.join("app/overrides").to_s,
      Rails.root.join("app/overrides").to_s,
    ]

    overrides.each { |override| Rails.autoloaders.main.ignore(override) }

    config.to_prepare do
      overrides.each do |override|
        Dir.glob("#{override}/**/*_override.rb").each do |file|
          load file
        end
      end
    end
  end
end
