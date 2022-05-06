# frozen_string_literal: true

class Boutique::OrdersController < Boutique::ApplicationController
  before_action :redirect_if_current_order_is_empty, except: %i[add show payment]
  before_action :find_order_by_secret_hash, only: %i[show payment]

  def add
    product_variant = Boutique::ProductVariant.find(params.require(:product_variant_id))
    amount = params[:amount].to_i if params[:amount].present?

    create_current_order if current_order.nil?

    current_order.add_line_item!(product_variant, amount: amount || 1)

    redirect_to action: :edit
  end

  def edit
  end

  def confirm
    current_order.assign_attributes(order_params)

    current_order.transaction do
      if current_order.confirm!
        gp_payment = Boutique::GoPay::Api.new.create_payment(current_order, controller: self,
                                                                            payment_method: params[:payment_method])
        current_order.payments.create!(remote_id: gp_payment["id"],
                                       payment_method: gp_payment["payment_instrument"])

        redirect_to gp_payment["gw_url"], allow_other_host: true
      else
        render :edit
      end
    end
  end

  def show
  end

  private
    def order_params
      params.require(:order).permit(:email,
                                    :first_name,
                                    :last_name,
                                    *addresses_strong_params,
                                    *line_items_strong_params)
    end

    def addresses_strong_params
      base = %i[id
                name
                company_name
                address_line_1
                city
                zip
                country_code]

      [
        :use_secondary_address,
        primary_address_attributes: base,
        secondary_address_attributes: base,
      ]
    end

    def line_items_strong_params
      [
        line_items_attributes: %i[id
                                  subscription_starts_at
                                  subscription_recurring]
      ]
    end

    def redirect_if_current_order_is_empty
      redirect_back fallback_location: main_app.root_url if current_order.nil?
    end

    def find_order_by_secret_hash
      @order = Boutique::Order.except_pending.find_by!(secret_hash: params[:id])
    end
end
