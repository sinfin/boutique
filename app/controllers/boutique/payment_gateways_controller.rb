  # frozen_string_literal: true

  class Boutique::PaymentGatewaysController < Boutique::ApplicationController
    include Boutique::RedirectAfterOrderPaid
    skip_before_action :verify_authenticity_token

    before_action :update_payment
    # for GO PAY it is returning at "http://folio-1.com/after_payment?order_id=joQNtFWDudZAxk9gOmFEUA&id=3186828749"
    # according to `return_url` in payment creation params
    # for COMGATE it return url is fixed and set at gateway , id of transaction is in params as `transId`
    def after_payment
      if @payment.paid? || @payment.order.waiting_for_offline_payment?
        flash[:success] = t(".success")

        redirect_after_order_paid(@payment.order)
      else
        flash[:alert] = t(".failure")

        redirect_to order_path(@payment.order.secret_hash)
      end
    end

    def payment_callback
      head :ok
    end

  private
    # def find_payment
    #   # FIXME: fix for recurrent payments
    #   # order = Boutique::Order.find_by_secret_hash!(params[:order_id])
    #   # @payment = order.payments.find_by_remote_id!(params[:id])

    def update_payment
      transaction_result = Boutique::PaymentGateway.process_callback(params.to_unsafe_h)
      result_hash = transaction_result.hash
      begin
        @payment = Boutique::Payment.find_by_remote_id!(result_hash[:transaction_id])
        @payment.update_state_from_gateway_check(result_hash)
      rescue ActiveRecord::RecordNotFound => error
        Raven.capture_error(error, extra: { params: })
      end
    end
  end
