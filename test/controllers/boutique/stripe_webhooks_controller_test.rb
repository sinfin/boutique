# frozen_string_literal: true

require "test_helper"

class Boutique::StripeWebhooksControllerTest < Boutique::ControllerTest
  include Boutique::Test::StripeApiMocker

  def setup
    super

    @order = create(:boutique_order, :confirmed)
    @payment = @order.payments.create!(remote_id: mocked_stripe_session_id,
                                       payment_gateway_provider: "stripe")
  end

  test "checkout.session.completed pays the payment" do
    stripe_check_transaction_api_call_mock

    post_webhook event_payload(type: "checkout.session.completed", object_id: mocked_stripe_session_id)

    assert_response :ok
    assert @payment.reload.paid?
    assert @order.reload.paid?
  end

  test "checkout.session.expired timeouts the payment" do
    stripe_check_transaction_api_call_mock(state: :expired)

    post_webhook event_payload(type: "checkout.session.expired", object_id: mocked_stripe_session_id)

    assert_response :ok
    assert @payment.reload.timeouted?
    assert @order.reload.confirmed?
  end

  test "event with invalid signature is rejected" do
    payload = event_payload(type: "checkout.session.completed", object_id: mocked_stripe_session_id)

    post stripe_payment_callback_url,
         params: payload,
         headers: { "Stripe-Signature" => "t=1,v1=invalid",
                    "Content-Type" => "application/json" }

    assert_response :bad_request
    assert @payment.reload.pending?
  end

  test "payment_intent event without matching payment is ignored" do
    Boutique::Stripe::UniversalGateway.any_instance
                                      .expects(:check_transaction)
                                      .never

    post_webhook event_payload(type: "payment_intent.succeeded", object_id: "pi_test_unknown")

    assert_response :ok
    assert @payment.reload.pending?
  end

  test "unhandled event type is ignored" do
    Boutique::Stripe::UniversalGateway.any_instance
                                      .expects(:check_transaction)
                                      .never

    post_webhook event_payload(type: "charge.refunded", object_id: "ch_test_123")

    assert_response :ok
    assert @payment.reload.pending?
  end

  private
    def post_webhook(payload)
      post stripe_payment_callback_url,
           params: payload,
           headers: { "Stripe-Signature" => valid_signature_header(payload),
                      "Content-Type" => "application/json" }
    end

    def valid_signature_header(payload)
      timestamp = Time.current
      signature = ::Stripe::Webhook::Signature.compute_signature(timestamp, payload, webhook_secret)

      "t=#{timestamp.to_i},v1=#{signature}"
    end

    def webhook_secret
      Boutique::PaymentGateway.new(:stripe).provider_gateway.webhook_secret
    end

    def event_payload(type:, object_id:)
      {
        id: "evt_test_1",
        object: "event",
        type:,
        data: { object: { id: object_id } }
      }.to_json
    end
end
