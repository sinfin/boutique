# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Folio::ApplicationControllerBase
  include Wipify::ApplicationControllerBase

  helper Folio::Engine.helpers
  helper Wipify::Engine.helpers
end
