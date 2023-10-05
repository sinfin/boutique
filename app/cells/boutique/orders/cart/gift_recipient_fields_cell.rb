# frozen_string_literal: true

class Boutique::Orders::Cart::GiftRecipientFieldsCell < Boutique::ApplicationCell
  def f
    model
  end

  def gift_recipient_notification_scheduled_for_input
    datetime = f.object.gift_recipient_notification_scheduled_for || 90.minutes.from_now.beginning_of_hour

    f.input :gift_recipient_notification_scheduled_for,
            required: true,
            input_html: { value: datetime.strftime("%d. %m. %Y, %H:%M") }
  end
end
