# frozen_string_literal: true

module Boutique::RedirectAfterOrderPaid
  extend ActiveSupport::Concern

  private
    def redirect_after_order_paid(order)
      if order.user.created_by_invite? && !order.user.invitation_accepted?
        session[:folio_user_invited_email] = order.user.email
        redirect_to main_app.user_invitation_path
      elsif url = Boutique.config.after_order_paid_redirect_url_proc.call(controller: self, order:)
        order_url = Boutique.config.after_order_paid_order_url_proc.call(controller: self, order:)

        redirect_to url, allow_other_host: true
      else
        redirect_to order_path(order.secret_hash)
      end

      add_flash_message_after_order_paid(order, order_url:)
    end

    def add_flash_message_after_order_paid(order, order_url: nil)
      translation_key = order.free? ? "success_free" : "success"

      message = if order_url.present?
        I18n.t("boutique.payment_gateways.after_payment.#{translation_key}.with_order_url", order_url:)
      else
        I18n.t("boutique.payment_gateways.after_payment.#{translation_key}.without_order_url")
      end

      flash[:success] = message
    end
end
