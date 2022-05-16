# frozen_string_literal: true

module Boutique
  # Preview all emails at http://localhost:3000/rails/mailers/boutique/order_mailer
  class OrderMailerPreview < ActionMailer::Preview
    def paid
      order = Boutique::Order.last

      OrderMailer.paid(order)
    end

    def paid_subsequent
      order = Boutique::Order.where(subsequent: true).last

      OrderMailer.paid_subsequent(order)
    end
  end
end
