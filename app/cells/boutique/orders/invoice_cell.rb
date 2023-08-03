# frozen_string_literal: true

class Boutique::Orders::InvoiceCell < ApplicationCell
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


  def shipping
    return nil unless model.requires_address?
    { vat_rate: model.shipping_vat_rate_value,
     price: model.shipping_price,
     price_vat: model.shipping_price_vat }
  end

  def vat_amounts
    @vat_amounts ||= begin
      va = model.line_items.group_by(&:vat_rate_value)
                           .transform_values do |line_items|
             line_items.sum(&:price_vat)
           end

      va[shipping[:vat_rate]] = (va[shipping[:vat_rate]] || 0) + shipping[:price_vat] if shipping.present?
      va
    end
  end

  def total_price_without_vat
    model.total_price - vat_amounts.values.sum
  end

  def hide_vat?
    return @hide_vat unless @hide_vat.nil?
    @hide_vat = model.try(:hide_invoice_vat?) == true
  end
end
