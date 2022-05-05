# frozen_string_literal: true

module Boutique
  # Preview all emails at http://localhost:3000/rails/mailers/boutique/order_mailer
  class OrderMailerPreview < ActionMailer::Preview
    def paid
      order = Boutique::Order.last

      OrderMailer.paid(order)
    end
  end
end
