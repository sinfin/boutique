# frozen_string_literal: true

module Wipify::CurrentOrder
  extend ActiveSupport::Concern

  included do
    helper_method :current_order
  end

  def current_order
    @current_order ||= begin
      order = current_order_scope.find_by(web_session_id: session.id.public_id)

      if current_user.present?
        if order.nil?
          order = base_scope.find_by(user: current_user)
        elsif order.user.nil?
          order.update!(user: current_user)
        end
      end

      order
    end
  end

  def create_current_order
    @current_order = Wipify::Order.create!(user: current_user,
                                           web_session_id: session.id.public_id)
  end

  private
    def current_order_scope
      Wipify::Order.pending
    end
end
