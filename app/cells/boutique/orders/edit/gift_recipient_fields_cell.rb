# frozen_string_literal: true

class Boutique::Orders::Edit::GiftRecipientFieldsCell < Boutique::ApplicationCell
  def f
    model
  end

  def gift_recipient_notification_scheduled_for_input
    date = f.object.gift_recipient_notification_scheduled_for || 90.minutes.from_now.beginning_of_hour

    f.input :gift_recipient_notification_scheduled_for,
            required: true,
            input_html: { value: date.strftime("%d. %m. %Y %H:%M") }
  end
end
