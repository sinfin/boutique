# frozen_string_literal: true

module Wipify::PriceHelper
  include ActionView::Helpers::NumberHelper

  # TODO: use config variable for currency
  def price(n, currency: "$")
    number_to_currency(n, unit: currency,
                          precision: 0,
                          delimiter: " ")
  end
end
