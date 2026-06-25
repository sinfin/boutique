# frozen_string_literal: true

class Boutique::ApplicationRecord < ActiveRecord::Base
  include Folio::Filterable
  include Folio::HtmlSanitization::Model
  include Folio::NillifyBlanks
  include Folio::RecursiveSubclasses
  include Folio::Sortable
  include Folio::ToLabel

  self.abstract_class = true

  class_attribute :fields_to_sanitize, default: []

  def self.has_sanitized_fields(*fields)
    self.fields_to_sanitize = fields
  end

  def folio_html_sanitization_config
    {
      enabled: self.class.fields_to_sanitize.any?,
      attributes: self.class.fields_to_sanitize.index_with(:string),
    }
  end

  def report_exception(exc, object = nil)
    puts("Overide me for better capturing exceptions `Boutique::ApplicationRecord#report_exception`")
    puts(exp)
    puts(object.inspect) if object.present?
  end
end
