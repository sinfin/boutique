# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Folio::ApplicationControllerBase
  include Boutique::ApplicationControllerBase

  helper Folio::Engine.helpers
  helper Boutique::Engine.helpers
end
