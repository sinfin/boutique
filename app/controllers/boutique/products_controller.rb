# frozen_string_literal: true

class Boutique::ProductsController < Boutique::ApplicationController
  def show
    redirect_to crossdomain_add_order_url(product_variant_slug: params[:id],
                                          subscription_id: params[:subscription_id])
  end
end
