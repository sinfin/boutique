# frozen_string_literal: true

class Folio::Console::Boutique::Orders::PaymentInfoCell < Folio::ConsoleCell
  def content
    ary = []

    if payment
      # TODO @dedekm link_to pay url
      ary << [
        payment.payment_gateway_provider,
        payment.payment_method,
      ].compact.join(" / ")
    else
      ary << t(".no_payment")
    end

    if voucher
      ary << link_to("voucher #{voucher.code}",
                     url_for([:edit, :console, voucher]))
    end

    label = ary.compact.join("<br>")

    if subscription && subscription.recurrent?
      cell("folio/console/ui/with_icon",
           label,
           icon: :reload,
           icon_options: { height: 16 })
    else
      label
    end
  end

  def voucher
    @voucher ||= options[:voucher] || model.try(:voucher)
  end

  def payment
    @payment ||= options[:payment] || model.try(:payments).try(:first)
  end

  def subscription
    @subscription ||= options[:subscription] || model.try(:subscription)
  end
end
