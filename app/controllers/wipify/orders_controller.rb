# frozen_string_literal: true

class Wipify::OrdersController < Wipify::ApplicationController
  before_action :redirect_if_current_order_is_empty, except: %i[add show thank_you]

  def add
    product_variant = Wipify::ProductVariant.find(params.require(:product_variant_id))
    amount = params[:amount].to_i if params[:amount].present?

    create_current_order if current_order.nil?

    current_order.add_line_item(product_variant, amount: amount || 1)

    redirect_to action: :show
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
      params.require(:order).permit(:email)
    end

    def redirect_if_current_order_is_empty
      redirect_to action: :show if current_order.nil?
    end
end
