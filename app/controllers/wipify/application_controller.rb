# frozen_string_literal: true

class Wipify::ApplicationController < ActionController::Base
  include Wipify::ApplicationControllerBase

  before_action :init_session

  private
    def init_session
      session[:init] = true if session.empty?
    end
end
