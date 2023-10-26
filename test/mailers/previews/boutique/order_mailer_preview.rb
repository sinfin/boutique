# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/boutique/order_mailer
class Boutique::OrderMailerPreview < ActionMailer::Preview
  def paid
    order = Boutique::Order.paid.last

    Boutique::OrderMailer.paid(order)
  end

  def paid_subsequent
    order = Boutique::Order.paid.last

    Boutique::OrderMailer.paid_subsequent(order)
  end

  def unpaid_reminder
    order = Boutique::Order.confirmed.last

    Boutique::OrderMailer.unpaid_reminder(order)
  end

  def gift_notification
    order = Boutique::Order.paid.where(gift: true).last
    Boutique::OrderMailer.gift_notification(order)
  end

  def gift_notification_with_invitation
    order = Boutique::Order.paid.where(gift: true).last
    Boutique::OrderMailer.gift_notification_with_invitation(order, "INVITATION_TOKEN")
  end
end
