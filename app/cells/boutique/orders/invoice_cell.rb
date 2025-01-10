# frozen_string_literal: true

class Boutique::Orders::InvoiceCell < ApplicationCell
  include Boutique::PriceHelper

  def price_with_precision(amount)
    price(amount, precision: 2, zero_as_number: true)
  end

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
    @vat_amounts ||= begin
      items = model.line_items.to_a

      if model.shipping_price > 0 && included_shipping_price_part == 0
        # rubocop:disable OpenStruct
        items << OpenStruct.new(vat_rate_value: model.shipping_vat_rate_value,
                                price_vat: model.shipping_price_vat)
        # rubocop:enable OpenStruct
      end

      items.group_by(&:vat_rate_value)
           .transform_values do |items|
        items.sum(&:price_vat)
      end
    end
  end

  def total_price_vat
    @total_price_vat ||= if included_shipping_price_part == 0
      model.line_items.sum(&:price_vat) + model.shipping_price_vat
    else
      vat_rate_value = model.line_items.first.vat_rate_value
      (model.total_price * (vat_rate_value.to_d / (100 + vat_rate_value))).round(2).to_f
    end
  end

  def total_price_without_vat
    (model.total_price - total_price_vat.to_d).to_f
  end

  def multiple_amount?
    model.line_items.any? { |line_item| line_item.amount > 1 }
  end

  def included_shipping_price_part
    if model.shipping_price_invoiced_separately?
      0
    else
      model.shipping_price.to_f / model.line_items.size
    end
  end
end
