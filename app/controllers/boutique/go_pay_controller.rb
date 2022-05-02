  # frozen_string_literal: true

  class Boutique::GoPayController < Boutique::ApplicationController
    before_action :find_and_update_payment

    def comeback
      if @payment.paid?
        flash[:success] = t(".success")
        redirect_to thank_you_order_path(@payment.order)
      else
        flash[:alert] = t(".failure")
        redirect_to failure_order_path(@payment.order)
      end
    end

    def notify
      head :ok
    end

  private
    def find_and_update_payment
      raise ActiveRecord::RecordNotFound if params[:id].nil?

      @payment = Boutique::Payment.find_by_remote_id!(params[:id])
      @payment.with_lock do
        @payment.order.lock!

        gp_payment = Boutique::GoPay::Api.new.find_payment(params[:id])

        if @payment.pending?
          @payment.payment_method = gp_payment["payment_instrument"]

          case gp_payment["state"]
          when "PAID"
            @payment.pay!
          when "CANCELED"
            @payment.cancel!
          when "TIMEOUTED"
            @payment.timeout!
          end
        end
      end
    end
  end
