# frozen_string_literal: true

module Boutique::Test
  module GoPayApiMocker
    private
      # id has to be unique whenever a single test drives more than one payment
      # through the gateway - Boutique::GoPayController looks the payment up by
      # its remote_id alone.
      def go_pay_create_payment_api_call_mock(id: 123)
        result = {
          "id" => id,
          "payment_instrument" => "PAYMENT_CARD",
          "gw_url" => mocked_go_pay_payment_gateway_url,
        }

        Boutique::GoPay::Api.any_instance
                            .expects(:create_payment)
                            .returns(result)
      end

      def go_pay_find_payment_api_call_mock(id: 123, state: "PAID", amount: 14900)
        result = {
          "id" => id,
          "payment_instrument" => "PAYMENT_CARD",
          "state" => state,
          "amount" => amount,
        }

        Boutique::GoPay::Api.any_instance
                            .expects(:find_payment)
                            .returns(result)
      end

      def go_pay_create_recurrent_payment_api_call_mock(id: 123)
        result = {
          "id" => id,
          "payment_instrument" => "PAYMENT_CARD",
        }

        Boutique::GoPay::Api.any_instance
                            .expects(:create_recurrent_payment)
                            .returns(result)
      end

      def mocked_go_pay_payment_gateway_url
        "https://test.gopay.com"
      end
  end
end
