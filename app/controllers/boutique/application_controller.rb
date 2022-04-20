# frozen_string_literal: true

class Boutique::ApplicationController < ActionController::Base
  layout "folio/application"

  include Folio::ApplicationControllerBase
  include Boutique::ApplicationControllerBase

  helper Folio::Engine.helpers

  before_action :init_session

  def default_url_options
    {}
  end

  private
    def init_session
      session[:init] = true if session.empty?
    end
end
