# frozen_string_literal: true

class Boutique::ProductsController < Boutique::ApplicationController
  def show
    permitted_params = params.permit(permitted_params_keys).to_h.symbolize_keys
    redirect_to crossdomain_add_item_checkout_url(permitted_params.merge(product_slug: params[:id]))
  end

  private
    def permitted_params_keys
      %i[product_id] + additional_permitted_params_keys
    end

    def additional_permitted_params_keys
      []
    end
end
