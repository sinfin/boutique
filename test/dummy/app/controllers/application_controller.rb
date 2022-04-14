# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Wipify::ApplicationControllerBase

  helper Wipify::Engine.helpers
end
