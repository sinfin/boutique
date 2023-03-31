# frozen_string_literal: true

class Boutique::ProductsController < Boutique::ApplicationController
  def show
    permitted_params = params.permit(permitted_params_keys).to_h.symbolize_keys
    redirect_to crossdomain_add_order_url(permitted_params.merge(product_variant_slug: params[:id]))
  end

  private
    def permitted_params_keys
      %i[subscription_id] + additional_permitted_params_keys
    end

    def additional_permitted_params_keys
      []
    end
end
