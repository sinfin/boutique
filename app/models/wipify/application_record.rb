# frozen_string_literal: true

module Wipify
  class ApplicationRecord < ActiveRecord::Base
    include Folio::Filterable
    include Folio::NillifyBlanks
    include Folio::RecursiveSubclasses
    include Folio::Sortable
    include Folio::ToLabel

    self.abstract_class = true
  end
end
