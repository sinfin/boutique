# frozen_string_literal: true

module Boutique::CreatePaymentAndRedirect
  extend ActiveSupport::Concern

  private
    def create_payment_and_redirect_to_payment_gateway(order)
      gateway_options = { payment_method: params[:payment_method],
                          return_url: return_after_pay_url(order_id: order.secret_hash, only_path: false),
                          callback_url: payment_callback_url(order_id: order.secret_hash, only_path: false) }

      # Manual (re)payment of an already-running recurring subscription order is a
      # recovery (e.g. the card expired and the automatic charge failed). Establish
      # a fresh recurring profile/token at the gateway and remember to move the
      # subscription onto that new token once this payment is captured (Order#pay).
      recurring_recovery = order.subsequent? && order.recurrent_payment? && order.subscription.present?
      order.update!(renewed_subscription: order.subscription) if recurring_recovery

      if order.first_of_subsequent? || recurring_recovery
        transaction = order.payment_gateway.start_recurring_transaction(order, gateway_options)
      else
        transaction = order.payment_gateway.start_transaction(order, gateway_options)
      end

      order.payments.create!(remote_id: transaction.transaction_id,
                             amount: order.total_price,
                             payment_gateway_provider: order.payment_gateway.provider,
                             payment_method: params[:payment_method]) # TODO: verify correctness
      # transaction.redirect? should be true
      redirect_to transaction.redirect_to, allow_other_host: true
    end
end
