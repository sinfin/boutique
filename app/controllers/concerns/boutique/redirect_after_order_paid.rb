# frozen_string_literal: true

module Boutique::RedirectAfterOrderPaid
  extend ActiveSupport::Concern

  private
    def redirect_after_order_paid(order)
      session[:boutique_order_paid_id] = order.id

      if order.user.created_by_invite? && !order.user.invitation_accepted?
        session[:folio_user_invited_email] = order.user.email
        redirect_to main_app.user_invitation_path
      elsif session[:boutique_after_order_paid_user_url] && try(:current_user)
        redirect_to session.delete(:boutique_after_order_paid_user_url),
                    allow_other_host: true
      else
        redirect_to order_path(order.secret_hash)
      end
    end
end
