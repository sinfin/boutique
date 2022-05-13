  # frozen_string_literal: true

  class Boutique::GoPayController < Boutique::ApplicationController
    before_action :find_and_update_payment

    def comeback
      if @payment.paid?
        flash[:success] = t(".success")

        if @payment.order.user.created_by_invite? && !@payment.order.user.invitation_accepted?
          session[:folio_user_invited_email] = @payment.order.user.email
          redirect_to main_app.user_invitation_path
        else
          redirect_to order_path(@payment.order.secret_hash)
        end
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
      order = Boutique::Order.find_by_secret_hash!(params[:order_id])
      @payment = order.payments.find_by_remote_id!(params[:id])

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
