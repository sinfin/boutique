# frozen_string_literal: true

module Boutique::ApplicationControllerBase
  extend ActiveSupport::Concern

  include Boutique::CurrentOrder

  included do
    before_action :redirect_after_order_paid_if_needed
  end

  private
    def redirect_after_order_paid_if_needed
      if session[:boutique_after_order_paid_user_url] && try(:current_user)
        redirect_to session.delete(:boutique_after_order_paid_user_url),
                    allow_other_host: true
      end
    end
end
