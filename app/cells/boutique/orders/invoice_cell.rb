# frozen_string_literal: true

class Boutique::Orders::InvoiceCell < ApplicationCell
  include Boutique::PriceHelper

  def billing_address
    @billing_address ||= model.secondary_address || model.primary_address
  end

  def billing_name
    billing_address.try(:company_name) || billing_address.try(:name) || model.full_name
  end

  def billing_address_first_line
    [
      billing_address.address_line_1,
      billing_address.address_line_2
    ].compact.join(" ")
  end

  def billing_address_second_line
    [
      billing_address.zip,
      billing_address.city
    ].compact.join(" ")
  end

  def billing_address_country_name
    t(".country_name.#{billing_address.country_code}", fallback: billing_address.country.translations["cs"])
  end

  def billing_address_identification_numbers
    @billing_address_identification_numbers ||= [
      ("IČ: #{billing_address.identification_number}" if billing_address.identification_number),
      ("DIČ: #{billing_address.vat_identification_number}" if billing_address.vat_identification_number),
    ].compact.join(", ")
  end

  def vat_amounts
    @vat_amounts ||= model.line_items.group_by(&:vat_rate_value)
                                     .transform_values do |line_items|
      line_items.sum(&:price_vat)
    end
  end

  def total_price_without_vat
    model.total_price - vat_amounts.values.sum
  end
end
