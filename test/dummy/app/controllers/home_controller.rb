# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @products = Boutique::Product.published
  end
end
