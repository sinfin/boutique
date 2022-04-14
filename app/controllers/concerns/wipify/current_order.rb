# frozen_string_literal: true

module Wipify::CurrentOrder
  extend ActiveSupport::Concern

  included do
    helper_method :current_order
  end

  def current_order
    @current_order ||= begin
      order = current_order_scope.find_by(web_session_id: session.id.public_id)

      if current_customer.present?
        if order.nil?
          order = base_scope.find_by(customer: current_customer)
        elsif order.customer.nil?
          order.update!(user: current_user)
        end
      end

      order
    end
  end

  def create_current_order
    @current_order = Wipify::Order.create!(customer: current_customer,
                                           web_session_id: session.id.public_id)
  end

  private
    def current_customer
      # TODO: make configurable
      nil
    end

    def current_order_scope
      Wipify::Order.pending
    end
end
