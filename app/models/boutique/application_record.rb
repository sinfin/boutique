# frozen_string_literal: true

class Boutique::ApplicationRecord < ActiveRecord::Base
  include Folio::Filterable
  include Folio::HasSanitizedFields
  include Folio::NillifyBlanks
  include Folio::RecursiveSubclasses
  include Folio::Sortable
  include Folio::ToLabel

  self.abstract_class = true

  def report_exception(exc, object = nil)
    puts("Overide me for better capturing exceptions `Boutique::ApplicationRecord#report_exception`")
    puts(exp)
    puts(object.inspect) if object.present?
  end
end
