# frozen_string_literal: true

module Boutique::CurrentOrder
  extend ActiveSupport::Concern

  included do
    helper_method :current_order
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
        elsif order.user.nil?
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
                                             web_session_id: session.id.public_id)
  end

  private
    def current_order_scope
      Boutique::Order.pending
    end
end
