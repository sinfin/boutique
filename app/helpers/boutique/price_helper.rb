# frozen_string_literal: true

module Boutique::PriceHelper
  include ActionView::Helpers::NumberHelper

  def price(n, currency: "Kč")
    number_to_currency(n, unit: currency,
                          precision: 0,
                          delimiter: " ")
  end
end
