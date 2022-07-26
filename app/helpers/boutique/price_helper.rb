# frozen_string_literal: true

module Boutique::PriceHelper
  include ActionView::Helpers::NumberHelper

  def price(n, currency: "Kč", zero_as_number: false)
    return I18n.t("boutique.free") if !zero_as_number && n.zero?

    number_to_currency(n, unit: currency,
                          precision: 0,
                          delimiter: " ")
  end
end
