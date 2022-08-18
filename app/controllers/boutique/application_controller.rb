# frozen_string_literal: true

class Boutique::ApplicationController < Boutique.config.parent_controller.constantize
  include Boutique::ApplicationControllerBase

  before_action :disable_application_breadcrumbs

  private
    def disable_application_breadcrumbs
      @hide_breadcrumbs = true
    end
end
