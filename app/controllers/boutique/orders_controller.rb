# frozen_string_literal: true

class Boutique::OrdersController < Boutique::ApplicationController
  before_action :redirect_if_current_order_is_empty, except: %i[add show thank_you]

  def add
    product_variant = Boutique::ProductVariant.find(params.require(:product_variant_id))
    amount = params[:amount].to_i if params[:amount].present?

    create_current_order if current_order.nil?

    current_order.add_line_item!(product_variant, amount: amount || 1)

    redirect_to redirect_options_after_line_item_added
  end

  def show
  end

  def edit
  end

  def update
  end

  def summary
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

  def thank_you
  end

  private
    def order_params
      params.require(:order).permit(:email,
                                    :first_name,
                                    :last_name,
                                    *addresses_strong_params)
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

    def redirect_if_current_order_is_empty
      if current_order.nil?
        if Boutique.using_cart
          redirect_to action: :show
        else
          redirect_back fallback_location: main_app.root_url
        end
      end
    end

    def redirect_options_after_line_item_added
      if Boutique.using_cart
        { action: :show }
      else
        { action: :edit }
      end
    end
end
