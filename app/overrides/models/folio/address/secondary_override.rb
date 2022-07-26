# frozen_string_literal: true

Folio::Address::Secondary.class_eval do
  validates :company_name,
            :identification_number,
            :vat_identification_number,
            presence: true
end
