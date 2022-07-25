# frozen_string_literal: true

module Boutique::PriceHelper
  include ActionView::Helpers::NumberHelper

  def price(n, currency: "Kč", precision: 0, zero_as_number: false)
    return I18n.t("boutique.free") if !zero_as_number && n.zero?

    number_to_currency(n, unit: currency,
                          precision:,
                          delimiter: " ")
  end
end
