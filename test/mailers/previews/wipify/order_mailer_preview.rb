# frozen_string_literal: true

module Wipify
  # Preview all emails at http://localhost:3000/rails/mailers/wipify/order_mailer
  class OrderMailerPreview < ActionMailer::Preview
    def confirmed
      order = Wipify::Order.last

      OrderMailer.confirmed(order)
    end

    def paid
      order = Wipify::Order.last

      OrderMailer.paid(order)
    end

    def dispatched
      order = Wipify::Order.last

      OrderMailer.dispatched(order)
    end
  end
end
