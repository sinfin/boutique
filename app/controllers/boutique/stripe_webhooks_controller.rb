# frozen_string_literal: true

class Boutique::StripeWebhooksController < Boutique::ApplicationController
  skip_before_action :verify_authenticity_token

  HANDLED_EVENT_TYPES = %w[checkout.session.completed
                           checkout.session.expired
                           payment_intent.succeeded
                           payment_intent.payment_failed]

  def payment_callback
    event = payment_gateway.provider_gateway
                           .construct_webhook_event(request.raw_post,
                                                    request.headers["Stripe-Signature"])

    update_payment_from_event(event) if event.type.in?(HANDLED_EVENT_TYPES)

    head :ok
  rescue ::Stripe::SignatureVerificationError, JSON::ParserError
    head :bad_request
  end

  private
    def payment_gateway
      Boutique::PaymentGateway.new(:stripe)
    end

    def update_payment_from_event(event)
      payment = Boutique::Payment.find_by(remote_id: event.data.object.id)

      # payment_intent.* events of checkout payments carry a pi_ id while the
      # payment is stored under the session cs_ id - ignore them silently,
      # the matching checkout.session.* event updates the payment
      return if payment.nil?

      # do not trust the event payload, verify the state against the Stripe API
      check_result = payment.payment_gateway.check_transaction(payment.remote_id)
      payment.update_state_from_gateway_check(check_result.hash)
    end
end
