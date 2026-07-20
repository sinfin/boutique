# frozen_string_literal: true

require "test_helper"

class Boutique::Stripe::UniversalGatewayTest < ActiveSupport::TestCase
  test "test_calls_used? is based on the api key prefix" do
    assert_equal true, gateway.test_calls_used?
    assert_equal false, Boutique::Stripe::UniversalGateway.new(api_key: "sk_live_123").test_calls_used?
  end

  test "make right call for creating payment" do
    payment_data = simple_payment_data
    return_url_with_placeholder = "https://eshop.com/after_payment?order_id=secret&session_id={CHECKOUT_SESSION_ID}"
    gateway_url = "https://checkout.stripe.com/c/pay/cs_test_123"

    freeze_time do
      expected_params = {
        mode: "payment",
        line_items: [{
          price_data: {
            currency: "czk",
            unit_amount: 10000,
            product_data: { name: "Order #123" },
          },
          quantity: 1,
        }],
        client_reference_id: "123",
        customer_email: "john@example.com",
        locale: "cs",
        success_url: return_url_with_placeholder,
        cancel_url: return_url_with_placeholder,
        expires_at: 1.hour.from_now.to_i,
        metadata: { order_reference_id: "123" },
      }

      ::Stripe::Checkout::SessionService.any_instance
                                        .expects(:create)
                                        .with(expected_params)
                                        .returns(stripe_checkout_session(url: gateway_url))

      result = gateway.start_transaction(payment_data)

      assert result.redirect?
      assert_equal gateway_url, result.redirect_to
      assert_equal "cs_test_123", result.transaction_id
      assert_equal :pending, result.hash[:state]
      assert_equal "PAYMENT_CARD", result.hash[:payment][:method]
    end
  end

  test "make right call to check open checkout session" do
    ::Stripe::Checkout::SessionService.any_instance
                                      .expects(:retrieve)
                                      .with("cs_test_123", { expand: ["payment_intent.latest_charge.balance_transaction"] })
                                      .returns(stripe_checkout_session(status: "open"))

    result = gateway.check_transaction(transaction_id: "cs_test_123")

    assert_not result.redirect?
    assert_equal "cs_test_123", result.transaction_id
    assert_equal :pending, result.hash[:state]
    assert_equal "PAYMENT_CARD", result.hash[:payment][:method]
    assert_nil result.hash[:payment][:fee]
    assert_nil result.hash[:payment][:card_number]
  end

  test "checked paid checkout session includes fee and card data" do
    session = stripe_checkout_session(status: "complete",
                                      payment_status: "paid",
                                      payment_intent: {
                                        id: "pi_test_123",
                                        object: "payment_intent",
                                        status: "succeeded",
                                        latest_charge: {
                                          id: "ch_test_123",
                                          object: "charge",
                                          balance_transaction: { id: "txn_test_123", object: "balance_transaction", fee: 590 },
                                          payment_method_details: { type: "card", card: { last4: "4242", exp_month: 3, exp_year: 2031 } },
                                        },
                                      })

    ::Stripe::Checkout::SessionService.any_instance
                                      .expects(:retrieve)
                                      .with("cs_test_123", { expand: ["payment_intent.latest_charge.balance_transaction"] })
                                      .returns(session)

    result = gateway.check_transaction(transaction_id: "cs_test_123")

    assert_equal "cs_test_123", result.transaction_id
    assert_equal :paid, result.hash[:state]
    assert_equal 5.9, result.hash[:payment][:fee]
    assert_equal "4242", result.hash[:payment][:card_number]
    assert_equal "03/31", result.hash[:payment][:card_valid]
  end

  test "checked expired checkout session is expired" do
    ::Stripe::Checkout::SessionService.any_instance
                                      .expects(:retrieve)
                                      .returns(stripe_checkout_session(status: "expired"))

    result = gateway.check_transaction(transaction_id: "cs_test_123")

    assert_equal :expired, result.hash[:state]
  end

  test "make right call to check payment intent" do
    { "succeeded" => :paid,
      "canceled" => :cancelled,
      "processing" => :pending,
      "requires_action" => :pending }.each do |stripe_status, expected_state|
      ::Stripe::PaymentIntentService.any_instance
                                    .expects(:retrieve)
                                    .with("pi_test_123", { expand: ["latest_charge.balance_transaction"] })
                                    .returns(stripe_payment_intent(status: stripe_status))

      result = gateway.check_transaction(transaction_id: "pi_test_123")

      assert_not result.redirect?
      assert_equal "pi_test_123", result.transaction_id
      assert_equal expected_state, result.hash[:state], "#{stripe_status} should map to #{expected_state}"
    end
  end

  test "make right call for creating recurring payment" do
    payment_data = simple_payment_data
    payment_data[:payment][:recurrence] = { cycle: :on_demand, period: 1, valid_to: Date.new(2099, 12, 31) }
    gateway_url = "https://checkout.stripe.com/c/pay/cs_test_123"

    ::Stripe::Checkout::SessionService.any_instance
                                      .expects(:create)
                                      .with do |params|
                                        params[:mode] == "payment" &&
                                        params[:customer_creation] == "always" &&
                                        params[:payment_intent_data] == { setup_future_usage: "off_session" }
                                      end
                                      .returns(stripe_checkout_session(url: gateway_url))

    result = gateway.start_recurring_transaction(payment_data)

    assert result.redirect?
    assert_equal gateway_url, result.redirect_to
    assert_equal "cs_test_123", result.transaction_id
    assert_equal :pending, result.hash[:state]
  end

  test "make right call for repeating recurring payment" do
    payment_data = repeat_payment_data

    ::Stripe::Checkout::SessionService.any_instance
                                      .expects(:retrieve)
                                      .with("cs_test_123", { expand: ["payment_intent"] })
                                      .returns(stripe_checkout_session(customer: "cus_test_123",
                                                                       payment_intent: {
                                                                         id: "pi_test_init",
                                                                         object: "payment_intent",
                                                                         payment_method: "pm_test_123",
                                                                       }))

    expected_params = {
      amount: 10000,
      currency: "czk",
      customer: "cus_test_123",
      payment_method: "pm_test_123",
      off_session: true,
      confirm: true,
      description: "Order Order #123",
      metadata: { order_reference_id: "123" },
    }

    ::Stripe::PaymentIntentService.any_instance
                                  .expects(:create)
                                  .with(expected_params, { idempotency_key: "charge-123" })
                                  .returns(stripe_payment_intent(id: "pi_test_charge"))

    result = gateway.repeat_recurring_transaction(payment_data)

    assert_not result.redirect?
    assert_nil result.redirect_to
    assert_equal "pi_test_charge", result.transaction_id
    assert_equal :pending, result.hash[:state]
    assert_equal "PAYMENT_CARD", result.hash[:payment][:method]
  end

  test "repeating recurring payment without saved mandate stops recurrence" do
    ::Stripe::Checkout::SessionService.any_instance
                                      .expects(:retrieve)
                                      .returns(stripe_checkout_session(customer: nil, payment_intent: nil))

    error = assert_raises(Boutique::PaymentGateway::Error) do
      gateway.repeat_recurring_transaction(repeat_payment_data)
    end

    assert error.stopped_recurrence?
  end

  test "repeating recurring payment converts hard declines to stopped recurrence" do
    stub_mandate_resolution

    ::Stripe::PaymentIntentService.any_instance
                                  .expects(:create)
                                  .raises(::Stripe::CardError.new("Your card was reported stolen.", nil,
                                                                  code: "card_declined",
                                                                  json_body: { error: { decline_code: "stolen_card" } }))

    error = assert_raises(Boutique::PaymentGateway::Error) do
      gateway.repeat_recurring_transaction(repeat_payment_data)
    end

    assert error.stopped_recurrence?
  end

  test "repeating recurring payment keeps soft declines as plain card errors" do
    stub_mandate_resolution

    ::Stripe::PaymentIntentService.any_instance
                                  .expects(:create)
                                  .raises(::Stripe::CardError.new("Authentication required.", nil,
                                                                  code: "authentication_required",
                                                                  json_body: { error: { code: "authentication_required" } }))

    error = assert_raises(::Stripe::CardError) do
      gateway.repeat_recurring_transaction(repeat_payment_data)
    end

    assert_equal "authentication_required", error.code
  end

  test "repeating recurring payment converts missing stripe records to stopped recurrence" do
    stub_mandate_resolution

    ::Stripe::PaymentIntentService.any_instance
                                  .expects(:create)
                                  .raises(::Stripe::InvalidRequestError.new("No such customer: cus_test_123", nil,
                                                                            code: "resource_missing"))

    error = assert_raises(Boutique::PaymentGateway::Error) do
      gateway.repeat_recurring_transaction(repeat_payment_data)
    end

    assert error.stopped_recurrence?
  end

  test "handles callbacks" do
    request_params = { "order_id" => "joQNtFWDudZAxk9gOmFEUA", "session_id" => "cs_test_123" }

    ::Stripe::Checkout::SessionService.any_instance
                                      .expects(:retrieve)
                                      .with("cs_test_123", { expand: ["payment_intent.latest_charge.balance_transaction"] })
                                      .returns(stripe_checkout_session(status: "open"))

    result = gateway.process_callback(request_params)

    assert_not result.redirect?
    assert_equal "cs_test_123", result.transaction_id
    assert_equal :pending, result.hash[:state]
  end

  private
    def gateway
      Boutique::Stripe::UniversalGateway.new(api_key: "sk_test_123", webhook_secret: "whsec_123")
    end

    def simple_payment_data
      {
        payer: {
          email: "john@example.com",
          phone: nil,
          first_name: "John",
          last_name: "Doe"
        },
        payment: {
          currency: "CZK",
          amount_in_cents: 10000,
          label: "Order #123",
          reference_id: "123",
          description: "Order Order #123",
          method: nil,
          product_name: "Order"
        },
        options: {
          country_code: "CZ",
          language_code: "cs",
          shop_return_url: "https://eshop.com/after_payment?order_id=secret",
          callback_url: "https://eshop.com/payment_callback?order_id=secret",
        },
        items: [{ type: "ITEM",
                  name: "Subscription",
                  price_in_cents: 10000,
                  count: 1,
                  vat_rate_percent: 21 }],
      }
    end

    def repeat_payment_data
      payment_data = simple_payment_data
      payment_data[:payment][:recurrence] = { init_transaction_id: "cs_test_123", period: 2 }
      payment_data
    end

    def stub_mandate_resolution
      ::Stripe::Checkout::SessionService.any_instance
                                        .expects(:retrieve)
                                        .returns(stripe_checkout_session(customer: "cus_test_123",
                                                                         payment_intent: {
                                                                           id: "pi_test_init",
                                                                           object: "payment_intent",
                                                                           payment_method: "pm_test_123",
                                                                         }))
    end

    def stripe_checkout_session(attributes = {})
      ::Stripe::Checkout::Session.construct_from({
        id: "cs_test_123",
        object: "checkout.session",
        url: nil,
        status: "open",
        payment_status: "unpaid",
        payment_intent: nil,
        customer: nil,
      }.merge(attributes))
    end

    def stripe_payment_intent(attributes = {})
      ::Stripe::PaymentIntent.construct_from({
        id: "pi_test_123",
        object: "payment_intent",
        status: "succeeded",
        latest_charge: nil,
      }.merge(attributes))
    end
end
