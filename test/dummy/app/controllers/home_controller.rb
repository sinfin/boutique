# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @products = Wipify::Product.published
  end
end
