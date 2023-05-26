# frozen_string_literal: true

class Boutique::OrdersController < Boutique::ApplicationController
  include Boutique::CreatePaymentAndRedirect

  before_action :find_order_by_secret_hash, only: %i[show payment]

  def show
    @use_boutique_adaptive_css = :no_background
  end

  def payment
    if @order.confirmed?
      create_payment_and_redirect_to_payment_gateway(@order)
    else
      flash[:error] = t(".error")
      redirect_back fallback_location: main_app.root_url
    end
  end

  private
    def find_order_by_secret_hash
      @order = Boutique::Order.except_pending.find_by!(secret_hash: params[:id])
    end
end
