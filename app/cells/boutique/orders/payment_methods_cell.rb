# frozen_string_literal: true

class Boutique::Orders::PaymentMethodsCell < Boutique::ApplicationCell
  PAYMENT_METHODS = %w[
    PAYMENT_CARD
    BANK_ACCOUNT
    APPLE_PAY
    GPAY
    PAYPAL
    BITCOIN
  ]

  def f
    model
  end

  def payment_methods
    return [] if ::Rails.env.test?

    enabled = Boutique::GoPay::Api.new.gateway.payment_instruments["enabledPaymentInstruments"]
                                              .map { |pm| pm["paymentInstrument"] }
    selected = PAYMENT_METHODS

    (selected & enabled).map do |pm|
      {
        title: payment_method_title(pm),
        value: pm
      }
    end
  end

  def payment_method_title(payment_method_string)
    t("boutique.go_pay.payment_method.#{payment_method_string}", fallback: payment_method_string.capitalize)
  end

  def payment_button(f, method, i)
    f.button :submit,
             method[:title],
             class: "btn btn-#{i.zero? ? "primary" : "secondary"} btn-xs-block b-orders-payment-methods__submit-btn",
             data: { "payment-method": method[:value] },
             style: ("display:none;" if method[:value] == "APPLE_PAY")
  end
end
