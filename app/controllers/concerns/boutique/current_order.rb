# frozen_string_literal: true

module Boutique::CurrentOrder
  extend ActiveSupport::Concern

  REFERRAL_URL_SESSION_KEY = "boutique_referrer_url"

  included do
    helper_method :current_order
    before_action :call_boutique_orders_get_referrer_url_proc
  end

  def current_order
    @current_order ||= begin
      if session && session.id
        order = current_order_scope.find_by(web_session_id: session.id.public_id)
      else
        order = nil
      end

      # using update_columns so that we don't get some random 500s by using update!
      if current_user.present?
        if order.nil?
          order = current_order_scope.where(user: current_user).order(id: :desc).first
        elsif order.user_id != current_user.id
          order.update_columns(folio_user_id: current_user.id,
                               updated_at: Time.current)
        end
      end

      order
    end
  end

  def create_current_order
    session[:init] = true if !session || !session.id

    @current_order = Boutique::Order.create!(user: current_user,
                                             web_session_id: session.id.public_id,
                                             referrer_url: session[REFERRAL_URL_SESSION_KEY])
  end

  private
    def current_order_scope
      Boutique::Order.pending
    end

    def call_boutique_orders_get_referrer_url_proc
      if Boutique.config.orders_get_referrer_url_proc && session[REFERRAL_URL_SESSION_KEY].blank?
        session[REFERRAL_URL_SESSION_KEY] = Boutique.config.orders_get_referrer_url_proc.call(self)
      end
    end
end
