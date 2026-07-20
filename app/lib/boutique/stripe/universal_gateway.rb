# frozen_string_literal: true

module Boutique
  module Stripe
    class UniversalGateway
      attr_reader :client, :webhook_secret

      DEFAULT_PAYMENT_METHOD = "PAYMENT_CARD"
      # Stripe minimum is 30 minutes; 1 hour aligns with
      # Boutique::Orders::PendingPaymentsCheckJob checking payments older than 1 hour
      SESSION_VALIDITY = 1.hour
      SESSION_ID_PLACEHOLDER = "{CHECKOUT_SESSION_ID}"
      # declines that cannot recover on retry - the subscription gets cancelled
      # right away instead of running through dunning
      HARD_DECLINE_CODES = %w[stolen_card lost_card pickup_card fraudulent]

      def initialize(api_key:, webhook_secret: nil)
        @api_key = api_key
        @webhook_secret = webhook_secret
        @client = ::Stripe::StripeClient.new(api_key)
      end

      def test_calls_used?
        @api_key.to_s.start_with?("sk_test_")
      end

      def process_callback(params)
        # return leg from the hosted checkout page - do not trust the params,
        # verify the session state against the Stripe API
        check_transaction(transaction_id: params["session_id"])
      end

      def check_transaction(transaction_id:)
        response_hash = if transaction_id.to_s.start_with?("cs_")
          check_checkout_session(transaction_id)
        else
          check_payment_intent(transaction_id)
        end

        Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: response_hash[:transaction_id],
          redirect_to: nil,
          hash: response_hash,
          array: nil
        )
      end

      def start_transaction(payment_data)
        session = create_checkout_session(payment_data)

        Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: session.id,
          redirect_to: session.url,
          hash: {
            transaction_id: session.id,
            state: :pending,
            payment: { method: DEFAULT_PAYMENT_METHOD },
          },
          array: nil
        )
      end

      def start_recurring_transaction(payment_data)
        session = create_checkout_session(payment_data,
                                          customer_creation: "always",
                                          payment_intent_data: { setup_future_usage: "off_session" })

        Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: session.id,
          redirect_to: session.url,
          hash: {
            transaction_id: session.id,
            state: :pending,
            payment: { method: DEFAULT_PAYMENT_METHOD },
          },
          array: nil
        )
      end

      def repeat_recurring_transaction(payment_data)
        payment = payment_data[:payment]
        init_transaction_id = payment.dig(:recurrence, :init_transaction_id)
        raise "[:payment][:recurrence][:init_transaction_id] is needed!" if init_transaction_id.blank?

        customer_id, payment_method_id = resolve_mandate(init_transaction_id)

        payment_intent = client.v1.payment_intents.create(
          {
            amount: payment[:amount_in_cents].to_i,
            currency: payment[:currency].to_s.downcase,
            customer: customer_id,
            payment_method: payment_method_id,
            off_session: true,
            confirm: true,
            description: payment[:description],
            metadata: { order_reference_id: payment[:reference_id] },
          },
          # deterministic key - hourly SubscriptionBot retries of the same order
          # must not create a second off-session charge
          { idempotency_key: "charge-#{payment[:reference_id]}" }
        )

        Boutique::PaymentGateway::ResponseStruct.new(
          transaction_id: payment_intent.id,
          redirect_to: nil,
          hash: {
            transaction_id: payment_intent.id,
            # confirmed by the webhook / Boutique::Orders::PendingPaymentsCheckJob
            state: :pending,
            payment: { method: DEFAULT_PAYMENT_METHOD },
          },
          array: nil
        )
      rescue ::Stripe::CardError => error
        raise convert_card_error(error)
      rescue ::Stripe::InvalidRequestError => error
        raise convert_invalid_request_error(error)
      end

      def refund_transaction(payment_data)
        raise NotImplementedError, "Stripe refunds are not implemented yet"
      end

      # raises ::Stripe::SignatureVerificationError for an invalid signature
      def construct_webhook_event(payload, signature)
        ::Stripe::Webhook.construct_event(payload, signature, webhook_secret.to_s)
      end

      private
        def create_checkout_session(payment_data, session_params = {})
          payment = payment_data[:payment]
          options = payment_data[:options] || {}
          return_url = url_with_session_id_placeholder(options[:shop_return_url])

          params = {
            mode: "payment",
            line_items: [{
              price_data: {
                currency: payment[:currency].to_s.downcase,
                unit_amount: payment[:amount_in_cents].to_i,
                product_data: { name: payment[:label].presence || payment[:product_name] },
              },
              quantity: 1,
            }],
            client_reference_id: payment[:reference_id],
            customer_email: payment_data.dig(:payer, :email),
            locale: options[:language_code].presence,
            success_url: return_url,
            cancel_url: return_url,
            expires_at: SESSION_VALIDITY.from_now.to_i,
            metadata: { order_reference_id: payment[:reference_id] },
          }.compact.merge(session_params)

          client.v1.checkout.sessions.create(params)
        end

        # Stripe replaces the placeholder with the real session id when redirecting back,
        # Boutique::PaymentGateway.process_callback dispatches on the `session_id` param.
        # The cancel_url needs the placeholder too, otherwise the return leg of a
        # cancelled payment could not be routed to :stripe.
        def url_with_session_id_placeholder(url)
          separator = url.to_s.include?("?") ? "&" : "?"
          "#{url}#{separator}session_id=#{SESSION_ID_PLACEHOLDER}"
        end

        def check_checkout_session(session_id)
          session = client.v1.checkout.sessions.retrieve(
            session_id,
            { expand: ["payment_intent.latest_charge.balance_transaction"] }
          )

          {
            transaction_id: session.id,
            state: convert_checkout_session_state(session),
            payment: payment_hash_for(session.payment_intent),
          }
        end

        def check_payment_intent(payment_intent_id)
          payment_intent = client.v1.payment_intents.retrieve(
            payment_intent_id,
            { expand: ["latest_charge.balance_transaction"] }
          )

          {
            transaction_id: payment_intent.id,
            state: convert_payment_intent_state(payment_intent.status),
            payment: payment_hash_for(payment_intent),
          }
        end

        def convert_checkout_session_state(session)
          case session.status
          when "expired"
            :expired
          when "complete"
            session.payment_status == "paid" ? :paid : :pending
          else # "open"
            :pending
          end
        end

        def convert_payment_intent_state(status)
          case status
          when "succeeded"
            :paid
          when "canceled"
            :cancelled
          else # "processing", "requires_payment_method", "requires_confirmation", "requires_action", "requires_capture"
            :pending
          end
        end

        def resolve_mandate(init_transaction_id)
          if init_transaction_id.to_s.start_with?("cs_")
            session = client.v1.checkout.sessions.retrieve(init_transaction_id,
                                                           { expand: ["payment_intent"] })
            customer_id = session.customer
            payment_method_id = session.payment_intent.try(:payment_method)
          else
            payment_intent = client.v1.payment_intents.retrieve(init_transaction_id)
            customer_id = payment_intent.customer
            payment_method_id = payment_intent.payment_method
          end

          if customer_id.blank? || payment_method_id.blank?
            raise stopped_recurrence_error("No saved customer/payment method for init transaction #{init_transaction_id}")
          end

          [customer_id, payment_method_id]
        end

        # issuer soft declines and authentication_required must keep the
        # subscription alive - dunning mails + manual recovery handle them;
        # hard declines mean the card is permanently gone
        def convert_card_error(error)
          return error unless error.error.try(:decline_code).in?(HARD_DECLINE_CODES)

          stopped_recurrence_error(error.message)
        end

        # resource_missing means the stored customer / payment method no longer
        # exists at Stripe - retrying cannot succeed
        def convert_invalid_request_error(error)
          return error unless error.code == "resource_missing"

          stopped_recurrence_error(error.message)
        end

        def stopped_recurrence_error(message)
          error = Boutique::PaymentGateway::Error.new(message)
          error.stopped_recurrence = true
          error
        end

        def payment_hash_for(payment_intent)
          payment_hash = {
            method: DEFAULT_PAYMENT_METHOD,
            fee: nil,
            card_number: nil,
            card_valid: nil,
          }

          charge = payment_intent.try(:latest_charge)
          return payment_hash if charge.blank?

          if (balance_transaction = charge.try(:balance_transaction)).present?
            # balance_transaction.fee is in the smallest currency unit,
            # Boutique::Payment#transfer_fee expects whole currency units
            payment_hash[:fee] = balance_transaction.fee / 100.0
          end

          if (card = charge.try(:payment_method_details).try(:card)).present?
            payment_hash[:card_number] = card.last4
            payment_hash[:card_valid] = format("%02d/%02d", card.exp_month, card.exp_year % 100)
          end

          payment_hash
        end
    end
  end
end
