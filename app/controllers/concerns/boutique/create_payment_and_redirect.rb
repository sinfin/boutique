# frozen_string_literal: true

module Boutique::CreatePaymentAndRedirect
  extend ActiveSupport::Concern

  private
    def create_payment_and_redirect_to_payment_gateway(order)
      transaction = order.payment_gateway.start_transaction(order, { payment_method: params[:payment_method],
                                                                      return_url: return_after_pay_url(order_id: order.secret_hash, only_path: false),
                                                                      callback_url: payment_callback_url(order_id: order.secret_hash, only_path: false) })
      order.payments.create!(remote_id: transaction.transaction_id,
                             payment_gateway_provider: order.payment_gateway.provider,
                             payment_method: params[:payment_method]) # TODO: verify correctness
      # transaction.redirect? should be true
      redirect_to transaction.redirect_to, allow_other_host: true
    end
end
