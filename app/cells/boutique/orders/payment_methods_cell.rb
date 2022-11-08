# frozen_string_literal: true

class Boutique::Orders::PaymentMethodsCell < Boutique::ApplicationCell
  STANDARD_PAYMENT_METHODS = %w[
    PAYMENT_CARD
    BANK_ACCOUNT
    APPLE_PAY
    GPAY
    PAYPAL
    BITCOIN
  ]

  RECURRENT_PAYMENT_METHODS = STANDARD_PAYMENT_METHODS - %w[ BANK_ACCOUNT BITCOIN ]

  def f
    model
  end

  def payment_methods
    return [] if ::Rails.env.test?

    enabled = Boutique::GoPay::Api.new.gateway.payment_instruments["enabledPaymentInstruments"]
                                              .map { |pm| pm["paymentInstrument"] }
    selected = STANDARD_PAYMENT_METHODS

    recurrence_required = f.object.line_items.any? { |li| li.subscription? && li.subscription_recurring? }

    (selected & enabled).map do |pm|
      {
        title: Boutique::Payment.payment_method_to_human(pm),
        value: pm,
        disabled: recurrence_required ? RECURRENT_PAYMENT_METHODS.exclude?(pm) : false,
        enabled_for_recurrent: RECURRENT_PAYMENT_METHODS.include?(pm)
      }
    end
  end

  def payment_button(f, method, i)
    f.button :submit,
             method[:title],
             class: "btn btn-#{i.zero? ? "primary" : "secondary"} btn-xs-block b-orders-payment-methods__submit-btn",
             data: { payment_method: method[:value], enabled_for_recurrent: method[:enabled_for_recurrent].to_s  },
             style: ("display:none;" if method[:value] == "APPLE_PAY"),
             disabled: method[:disabled]
  end
end
