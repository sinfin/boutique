  # frozen_string_literal: true

  class Boutique::GoPayController < Boutique::ApplicationController
    include Boutique::RedirectAfterOrderPaid

    before_action :find_and_update_payment

    def comeback
      if @payment.paid? || @payment.order.waiting_for_offline_payment?
        flash[:success] = t(".success")

        redirect_after_order_paid(@payment.order)
      else
        flash[:alert] = t(".failure")

        redirect_to order_path(@payment.order.secret_hash)
      end
    end

    def notify
      head :ok
    end

  private
    def find_and_update_payment
      # FIXME: fix for recurrent payments
      # order = Boutique::Order.find_by_secret_hash!(params[:order_id])
      # @payment = order.payments.find_by_remote_id!(params[:id])

      @payment = Boutique::Payment.find_by_remote_id!(params[:id])

      @payment.with_lock do
        @payment.order.lock!

        gp_payment = Boutique::GoPay::Api.new.find_payment(params[:id])

        if @payment.pending?
          @payment.payment_method = gp_payment["payment_instrument"]

          case gp_payment["state"]
          when "PAID"
            @payment.pay!
          when "PAYMENT_METHOD_CHOSEN"
            unless @payment.order.waiting_for_offline_payment?
              @payment.order.wait_for_offline_payment!
              @payment.touch
            end
          when "CANCELED"
            @payment.cancel!
          when "TIMEOUTED"
            @payment.timeout!
          end
        end
      end
    end
  end
