# frozen_string_literal: true

already_loaded = Folio::Site.method_defined?(:billing_enabled?)
return if already_loaded

Folio::Site.class_eval do
  validates :billing_name,
            :billing_address_line_1,
            :billing_address_line_2,
            :billing_identification_number,
            :billing_vat_identification_number,
            :billing_note,
            presence: true

  def billing_enabled?
    true
  end

  def self.additional_params
    %i[
      billing_name
      billing_address_line_1
      billing_address_line_2
      billing_identification_number
      billing_vat_identification_number
      billing_note
    ]
  end
end
