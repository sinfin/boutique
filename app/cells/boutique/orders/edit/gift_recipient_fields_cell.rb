# frozen_string_literal: true

class Boutique::Orders::Edit::GiftRecipientFieldsCell < Boutique::ApplicationCell
  def f
    model
  end

  def gift_recipient_notification_date_input
    date = f.object.gift_recipient_notification_date || Date.today

    f.input :gift_recipient_notification_date,
            required: true,
            input_html: { value: date.strftime("%-d. %-m. %Y") }
  end
end
