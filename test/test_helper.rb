# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require Folio::Engine.root.join("test/test_helper_base")
require Boutique::Engine.root.join("test/go_pay_api_mocker")

ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)

require "rails/test_help"
require "factory_bot"

FactoryBot.find_definitions

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  parallelize
end

class Boutique::ControllerTest < ActionDispatch::IntegrationTest
  include Boutique::Engine.routes.url_helpers

  def setup
    create_and_host_site
  end
end

require "mocha/minitest"
require "minitest/mock"
require "minitest/stub_any_instance"
