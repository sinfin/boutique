# frozen_string_literal: true

class Boutique::Addresses::FieldsCell < Boutique::ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  # TODO: make configurable
  def country_code_priority
    ["CZ", "SK"]
  end
end
