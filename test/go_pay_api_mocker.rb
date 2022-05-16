# frozen_string_literal: true

module Boutique::Test
  module GoPayApiMocker
    private
      def go_pay_create_payment_api_call_mock
        result = {
          "id" => 123,
          "payment_instrument" => "PAYMENT_CARD",
          "gw_url" => mocked_go_pay_payment_gateway_url,
        }

        Boutique::GoPay::Api.any_instance
                            .expects(:create_payment)
                            .returns(result)
      end

      def go_pay_find_payment_api_call_mock(state: "PAID")
        result = {
          "id" => 123,
          "payment_instrument" => "PAYMENT_CARD",
          "state" => state,
        }

        Boutique::GoPay::Api.any_instance
                            .expects(:find_payment)
                            .returns(result)
      end

      def go_pay_create_recurrent_payment_api_call_mock
        result = {
          "id" => 123,
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
