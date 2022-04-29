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

    if current_order.confirm!
      redirect_to action: :thank_you, id: current_order.number
    else
      render :edit
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
        if Rails.application.config.boutique_using_cart
          redirect_to action: :show
        else
          redirect_back fallback_location: main_app.root_url
        end
      end
    end

    def redirect_options_after_line_item_added
      if Rails.application.config.boutique_using_cart
        { action: :show }
      else
        { action: :edit }
      end
    end
end
