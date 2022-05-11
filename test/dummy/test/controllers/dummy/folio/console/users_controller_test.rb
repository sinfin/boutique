# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("test/controllers/folio/console/users_controller_test").to_s

module Folio
  module Console
    module Dummy
      class UsersControllerTest < ::Folio::Console::UsersControllerTest
      end
    end
  end
end
