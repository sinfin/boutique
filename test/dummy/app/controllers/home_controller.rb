# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @products = Boutique::Product.published.includes(:master_variant, :variants)
  end
end
