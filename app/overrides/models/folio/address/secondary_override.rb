# frozen_string_literal: true

Folio::Address::Secondary.class_eval do
  def self.fields_layout
    [
      :company_name,
      { address_line_1: 8, address_line_2: 4 },
      { city: 7, zip: 5 },
      :country_code,
      :identification_number,
      :vat_identification_number,
    ]
  end

  def self.show_for_attributes
    %i[
      company_name
      address_line_1
      address_line_2
      city
      zip
      country_code
      identification_number
      vat_identification_number
    ]
  end
end
