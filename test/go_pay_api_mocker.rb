# frozen_string_literal: true

module Boutique::Test
  module GoPayApiMocker
    private
      def go_pay_start_transaction_api_call_mock
        response_hash = {
          transaction_id: 123,
          redirect_to: mocked_go_pay_payment_gateway_url,
        }

        result = Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: response_hash[:redirect_to],
          hash: response_hash,
          array: nil
        )

        Boutique::GoPay::UniversalGateway.any_instance
                            .expects(:start_transaction)
                            .returns(result)
      end

      def go_pay_check_transaction_api_call_mock(state: :paid)
        response_hash = {
          transaction_id: 123,
          redirect_to: nil,
          state: ,
          payment: { method: "PAYMENT_CARD" }
        }

        result = Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: response_hash[:redirect_to],
          hash: response_hash,
          array: nil
        )

        Boutique::GoPay::UniversalGateway.any_instance
                            .expects(:check_transaction)
                            .returns(result)
      end

      def go_pay_start_recurring_transaction_api_call_mock
        response_hash = {
          transaction_id: 123,
          redirect_to: mocked_go_pay_payment_gateway_url,
        }

        result = Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: response_hash[:redirect_to],
          hash: response_hash,
          array: nil
        )

        Boutique::GoPay::UniversalGateway.any_instance
                            .expects(:start_recurring_transaction)
                            .returns(result)
      end

      def go_pay_repeat_recurring_transaction_api_call_mock
        response_hash = {
          transaction_id: 123,
          redirect_to: nil,
          payment: { method: "PAYMENT_CARD" }
        }

        result = Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: response_hash[:redirect_to],
          hash: response_hash,
          array: nil
        )

        Boutique::GoPay::UniversalGateway.any_instance
                            .expects(:repeat_recurring_transaction)
                            .returns(result)
      end

      def mocked_go_pay_payment_gateway_url
        "https://test.gopay.com"
      end
  end
end
