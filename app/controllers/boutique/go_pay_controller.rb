  # frozen_string_literal: true

  class Boutique::GoPayController < Boutique::ApplicationController
    include Boutique::RedirectAfterOrderPaid

    before_action :update_payment
    # for GO PAY it is returning at "http://folio-1.com/after_payment?order_id=joQNtFWDudZAxk9gOmFEUA&id=3186828749"
    # according to `return_url` in payment creation params
    # for COMGATE it return url is fixed and set at gateway , id of transaction is in params as `transId`
    def comeback
      if @payment.paid? || @payment.order.waiting_for_offline_payment?
        flash[:success] = t(".success")

        redirect_after_order_paid(@payment.order)
      else
        flash[:alert] = t(".failure")

        redirect_to order_path(@payment.order.secret_hash)
      end
    end

    def notify # callback_url
      head :ok
    end

  private
    # def find_payment
    #   # FIXME: fix for recurrent payments
    #   # order = Boutique::Order.find_by_secret_hash!(params[:order_id])
    #   # @payment = order.payments.find_by_remote_id!(params[:id])

    def update_payment
      transaction_result = Boutique::PaymentGateway.process_callback(params)
      result_hash = transaction_result.hash

      @payment = Boutique::Payment.find_by_remote_id!(result_hash[:transaction_id])

      @payment.with_lock do
        @payment.order.lock!

        if @payment.pending?
          @payment.payment_method = result_hash[:method]

          case result_hash[:state]
          when :paid
            @payment.pay!
          when :payment_method_chosen
            unless @payment.order.waiting_for_offline_payment?
              @payment.order.wait_for_offline_payment!
              @payment.touch
            end
          when :cancelled
            @payment.cancel!
          when :expired, :timeouted
            @payment.timeout!
          end
        end
      end
    end
  end
