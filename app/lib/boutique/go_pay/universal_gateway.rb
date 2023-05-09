# frozen_string_literal: true

require_relative "gopay_ruby_override"

module Boutique
  module GoPay
    class UniversalGateway
      attr_reader :gp_gateway
      # TEST_GATEWAY_URL = "https://gw.sandbox.gopay.com/api"
      TEST_GATEWAY_URL = "https://testgw.gopay.cz"
      PRODUCTION_GATEWAY_URL = "https://gate.gopay.cz"
      CURRENCY = "CZK"
      DEFAULT_PAYMENT_METHOD = "PAYMENT_CARD"

      def initialize (test_calls:, merchant_gateway_id:, client_id:, client_secret:)
        @test_calls = test_calls
        @gp_gateway = ::GoPay::Gateway.new(gate: test_calls == false ? PRODUCTION_GATEWAY_URL : TEST_GATEWAY_URL,
                                            goid: merchant_gateway_id,
                                            client_id:,
                                            client_secret:)
      end

      def test_calls_used?
        @test_calls == true
      end

      def process_callback(params)
        # callback is just PING with transaction id
        check_transaction(transaction_id: params["id"])
      end

      def check_transaction(transaction_id:)
        resp = gp_gateway.retrieve(transaction_id)
        response_hash = convert_response_to_hash(resp)

        Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: nil, # response_hash[:redirect_to],
          hash: response_hash.except(:redirect_to),
          array: nil
        )
      end

      def start_transaction(payment_data)
        resp = gp_gateway.create(payment_hash(payment_data))
        response_hash = convert_response_to_hash(resp)

        Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: response_hash[:redirect_to],
          hash: response_hash,
          array: nil
        )
      end

      def start_recurring_transaction(payment_data)
        recurrence_hash = payment_data[:payment].delete(:recurrence)
        if recurrence_hash.blank?
          recurrence_hash = { cycle: "ON_DEMAND",
                              period: 1,
                              valid_to: Date.today + 100.years }
        end

        payload = payment_hash(payment_data)
        payload["recurrence"] = recurrence_params_for(recurrence_hash)

        resp = gp_gateway.create(payload)
        response_hash = convert_response_to_hash(resp)

        Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: response_hash[:redirect_to],
          hash: response_hash,
          array: nil
        )
      end

      def repeat_recurring_transaction(payment_data)
        recurrence_hash = payment_data[:payment].delete(:recurrence)
        init_tr_id = recurrence_hash.present? ? recurrence_hash[:init_transaction_id] : nil
        raise "[:payment][:recurrence][:init_transaction_id] is needed!" if init_tr_id.blank?

        payload = payment_hash(payment_data).slice(:amount, :currency, :order_number, :order_description, :items, :additional_params)

        resp = gp_gateway.create_recurrent_payment(init_tr_id, payload)
        response_hash = convert_response_to_hash(resp)

        Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: response_hash[:redirect_to],
          hash: response_hash,
          array: nil
        )
      end

      def refund_transaction(payment_data)
        resp = gp_gateway.refund(payment_data[:transaction_id], payment_data[:payment][:amount_in_cents])
        response_hash = convert_response_to_hash(resp)
        response_hash[:state] = resp["result"].downcase.to_sym
        response_hash.delete(:payment)
        response_hash.delete(:payer)

        Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: response_hash[:redirect_to],
          hash: response_hash,
          array: nil
        )
      end

      private
        def payment_hash(payment_data)
          # payment_data = {
          #   payer: { email: "john@example.com",
          #            phone: "+420777888999",
          #            first_name:,
          #           last_name:,
          #          street_line:,
          #          city:,
          #         postal_code:,
          #         country_code:  },
          #   merchant: { target_shop_account: "12345678/1234" }
          #   payment: { currency: "CZK",
          #              amount_in_cents: 100, # 1 CZK
          #              label: "#2023-0123",
          #              reference_id: "#2023-0123",
          #              description:,
          #              method: "ALL"
          #              apple_pay_payload: "apple pay payload",
          #              dynamic_expiration: false,
          #              expiration_time: "10h",
          #              # init_reccuring_payments: true,
          #              product_name: "Usefull things" },
          #   options: {
          #     country_code: "DE",
          #     # embedded_iframe: false, # redirection after payment  # gateway variable
          #     language_code: "sk",
          #      shop_return_url:,
          #      callback_url:,
          #   },
          #   test: true
          # }


          contact = {
            first_name: payment_data[:payer][:first_name],
            last_name: payment_data[:payer][:last_name],
            phone_number: payment_data[:payer][:phone],
            email: payment_data[:payer][:email],
            city: payment_data[:payer][:city],
            street: payment_data[:payer][:street_line],
            postal_code: payment_data[:payer][:postal_code],
            country_code: payment_data[:payer][:country_code3],
          }

          result = {
            payer: {
              default_payment_instrument: payment_data[:payment][:method].presence || DEFAULT_PAYMENT_METHOD,
              contact:
            },
            items: nil,
            amount: payment_data[:payment][:amount_in_cents],
            currency: payment_data[:payment][:currency],
            order_number: payment_data[:payment][:reference_id],
            order_description: payment_data[:payment][:description],
            lang: payment_data[:options][:language_code],
            callback: {
              return_url: payment_data[:options][:shop_return_url],
              notification_url: payment_data[:options][:callback_url],
            },

          }

          # if order.line_items.any? { |li| li.subscription? && li.subscription_recurring? }

          result
        end

        def recurrence_params_for(rec_data)
          {
            recurrence_cycle: (rec_data[:cycle] || "ON_DEMAND").to_s.upcase,
            recurrence_period: rec_data[:period] || 1,
            recurrence_date_to: rec_data[:valid_to].to_s
          }
        end

        def convert_response_to_hash(resp)
          response_hash = {
            code: 0,
            message: "OK",
            transaction_id: resp["id"],
            state: convert_state(resp["state"]),
            redirect_to: resp["gw_url"],
            payment: {
              amount_in_cents: resp["amount"],
              currency: resp["currency"],
              label: "",
              reference_id: resp["order_number"],
              method: resp["payment_instrument"],
              product_name: "",
              fee: nil,
              variable_symbol: nil,
              description: nil,
            },
            payer: {
              email: resp.dig("payer", "contact", "email"),
              phone: resp.dig("payer", "contact", "phone_number"),
              first_name: resp.dig("payer", "contact", "first_name"),
              last_name: resp.dig("payer", "contact", "last_name"),
              street_line: resp.dig("payer", "contact", "street"),
              city: resp.dig("payer", "contact", "city"),
              postal_code: resp.dig("payer", "contact", "postal_code"),
              country_code2: nil,
              country_code3: resp.dig("payer", "contact", "country_code"),
              account_number: resp.dig("payer", "bank_account", "iban"),
              account_name: resp.dig("payer", "bank_account", "account_name")
            }
          }

          if resp.dig("recurrence").present?
            valid_to = resp.dig("recurrence", "recurrence_date_to")
            valid_to = Date.parse(valid_to) unless valid_to.nil?

            response_hash[:payment][:recurrence] = {
              cycle: resp.dig("recurrence", "recurrence_cycle")&.downcase&.to_sym,
              period: resp.dig("recurrence", "recurrence_period"),
              valid_to:,
              state:  convert_state(resp.dig("recurrence", "recurrence_state"))
            }
          end
          if resp["parent_id"].present?
            if response_hash[:payment][:recurrence].nil?
              response_hash[:payment][:recurrence] = { init_transaction_id: resp["parent_id"] }
            else
              response_hash[:payment][:recurrence][:init_transaction_id] = resp["parent_id"]
            end
          end

          if resp.dig("preauthorization").present?
            response_hash[:payment][:preauthorization] = {
              requested: resp.dig("preauthorization", "requested"),
              state:  convert_state(resp.dig("preauthorization", "state"))
            }
          end
          response_hash
        end

        def convert_state(state_str)
          ## payment
          # CREATED Payment created
          # PAID Payment has already been paid
          # CANCELED Payment declined
          # PAYMENT_METHOD_CHOSEN Payment method confirmed
          # TIMEOUTED The payment has expired
          # AUTHORIZED Payment pre-authorized
          # REFUNDED Payment refunded
          # PARTIALLY_REFUNDED Payment partially refunded

          ## preauthorization
          #  REQUESTED Pre-authorization created
          #  AUTHORIZED Pre-authorized
          #  CAPTURED Pre-authorion captured
          #  CANCELED

          # #recurrence
          # REQUESTED Recurring payment created, waiting for authorization of initial payment
          # STARTED Payment recurrence active
          # STOPPED Payment recurring canceled

          return nil if state_str.blank?

          case state_str
          when "CREATED"
            :pending
          else
            state_str.downcase.to_sym
          end
        end
    end
  end
end
