# frozen_string_literal: true

class Boutique::ApplicationRecord < ActiveRecord::Base
  include Folio::Filterable
  include Folio::HasSanitizedFields
  include Folio::NillifyBlanks
  include Folio::RecursiveSubclasses
  include Folio::Sortable
  include Folio::ToLabel

  self.abstract_class = true
end
