# frozen_string_literal: true

module Boutique::Test
  module StripeApiMocker
    private
      def stripe_start_transaction_api_call_mock
        response_hash = {
          transaction_id: mocked_stripe_session_id,
          state: :pending,
          payment: { method: "PAYMENT_CARD" }
        }

        result = Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: mocked_stripe_payment_gateway_url,
          hash: response_hash,
          array: nil
        )

        Boutique::Stripe::UniversalGateway.any_instance
                            .expects(:start_transaction)
                            .returns(result)
      end

      def stripe_check_transaction_api_call_mock(state: :paid)
        response_hash = {
          transaction_id: mocked_stripe_session_id,
          state:,
          payment: { method: "PAYMENT_CARD",
                     fee: nil,
                     card_number: "4242",
                     card_valid: "12/29" }
        }

        result = Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: nil,
          hash: response_hash,
          array: nil
        )

        Boutique::Stripe::UniversalGateway.any_instance
                            .expects(:check_transaction)
                            .returns(result)
      end

      def stripe_start_recurring_transaction_api_call_mock
        response_hash = {
          transaction_id: mocked_stripe_session_id,
          state: :pending,
          payment: { method: "PAYMENT_CARD" }
        }

        result = Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: mocked_stripe_payment_gateway_url,
          hash: response_hash,
          array: nil
        )

        Boutique::Stripe::UniversalGateway.any_instance
                            .expects(:start_recurring_transaction)
                            .returns(result)
      end

      def stripe_repeat_recurring_transaction_api_call_mock
        response_hash = {
          transaction_id: mocked_stripe_payment_intent_id,
          state: :pending,
          payment: { method: "PAYMENT_CARD" }
        }

        result = Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: nil,
          hash: response_hash,
          array: nil
        )

        Boutique::Stripe::UniversalGateway.any_instance
                            .expects(:repeat_recurring_transaction)
                            .returns(result)
      end

      def mocked_stripe_session_id
        "cs_test_a1b2c3"
      end

      def mocked_stripe_payment_intent_id
        "pi_test_d4e5f6"
      end

      def mocked_stripe_payment_gateway_url
        "https://checkout.stripe.com/c/pay/#{mocked_stripe_session_id}"
      end
  end
end
