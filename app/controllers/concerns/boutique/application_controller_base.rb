# frozen_string_literal: true

module Boutique::ApplicationControllerBase
  extend ActiveSupport::Concern

  include Boutique::CurrentOrder

  included do
    before_action :disable_application_breadcrumbs
  end

  private
    def disable_application_breadcrumbs
      @hide_breadcrumbs = true
    end
end
