# Boutique
e-shop plugin for [Folio](http://github.com/sinfin/folio)

## Payment Gateway
 Boutique unifies payment process through `Boutique::PaymentGateway`, which creates standardized payment params (see bellow) and sends them to selected payment provider gateway. Enabled payment providers are configured in [initializer](/test/dummy/config/initializers/payment_gateways.rb).

 ```ruby
   pg = Boutique::PaymentGateway.new(:comgate)
   pg.start_recurring_transaction(order)
 ```

 ### Standardized payment params
 as expected on input for Boutique's `Boutique::GoPay::UniversalGateway` or `Comgate::Gateway`from [comgate_ruby gem](http://github.com/sinfin/comgate_ruby).
 If you always send these params, any payment provider should handle payment. If some params are ommitedd, it can work for one, but fail for other.

 ```ruby
  { payer: {
      email: "ja.prvni@seznam.cz", # *required
      phone: nil,
      first_name: nil,
      last_name: nil,
      street_line:,
      city:,
      postal_code:,
      country_code2:,
      country_code3:,
      account_number:,
      account_name:
    },

    payment: {
      currency: "CZK", # *required
      amount_in_cents: 9900, # *required
      label: "payment label",
      reference_id: "payment_app_reference_OR_order_number",
      description: "Payment content(?) description",
      method: "ALL",
      product_name: "Thing",
      apple_pay_payload: "apple pay payload",
      dynamic_expiration: false,
      expiration_time: "10h",
      init_reccuring_payments: true,
      recurrence: {
        init_transaction_id: "DVCJ-J8KN-71LR",
        cycle: :month,
        period: 1,
        valid_to: Date.new(2025, 12, 31),
      }
    },
    options: {
      country_code: "CZ",
      language_code: "cs",
      shop_return_url: nil,
      callback_url: nil
    },
    items: [
      {
        type: "ITEM",
        name: "Je to kulatý – Měsíční (6. 6. 2023 – 6. 7. 2023)",
        price_in_cents: 9900,
        count: 1,
        vat_rate_percent: 21
      }
    ],
    test: true
}

```

## Scheduled jobs
For correct funcionality, you have to schedule `Boutique::MailerBotJob` , `Boutique::SubscriptionBotJob` to run every 1 hour.
