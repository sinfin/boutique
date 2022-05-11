# frozen_string_literal: true

module Boutique::CurrentOrder
  extend ActiveSupport::Concern

  included do
    helper_method :current_order
  end

  def current_order
    @current_order ||= begin
      order = current_order_scope.find_by(web_session_id: session.id.public_id)

      # using update_columns so that we don't get some random 500s by using update!
      if current_user.present?
        if order.nil?
          order = current_order_scope.find_by(user: current_user)
        elsif order.user.nil?
          order.update_columns(folio_user_id: current_user.id,
                               updated_at: Time.current)
        end

        if order.user && (order.first_name.blank? || order.last_name.blank?)
          order.update_columns(first_name: order.first_name.presence || current_user.first_name.presence,
                               last_name: order.last_name.presence || current_user.last_name.presence,
                               updated_at: Time.current)

        end
      end

      order
    end
  end

  def create_current_order
    @current_order = Boutique::Order.create!(user: current_user,
                                           web_session_id: session.id.public_id)
  end

  private
    def current_order_scope
      Boutique::Order.pending
    end
end
