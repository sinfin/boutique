# frozen_string_literal: true

class Wipify::OrdersController < Wipify::ApplicationController
  def add
    product_variant = Wipify::ProductVariant.find(params.require(:product_variant_id))
    amount = params[:amount].to_i if params[:amount].present?

    create_current_order if current_order.nil?

    current_order.add_line_item(product_variant, amount: amount || 1)

    # TODO
    redirect_to main_app.root_url
  end
end
