# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require Folio::Engine.root.join("test/test_helper_base")

ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)

require "rails/test_help"
require "factory_bot"

FactoryBot.find_definitions

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  parallelize
end

require "mocha/minitest"
