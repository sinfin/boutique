# frozen_string_literal: true

module Boutique
  class OrderMailer < ApplicationMailer
    def confirmed(order)
      @greeting = "Hi"

      mail to: order.email
    end

    def paid(order)
      @greeting = "Hi"

      mail to: order.email
    end

    def dispatched(order)
      @greeting = "Hi"

      mail to: order.email
    end
  end
end
