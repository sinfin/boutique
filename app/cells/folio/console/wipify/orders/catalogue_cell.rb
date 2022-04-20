# frozen_string_literal: true

class Folio::Console::Wipify::Orders::CatalogueCell < Folio::ConsoleCell
  include Folio::Console::IndexHelper

  def show
    @klass = Wipify::Order
    render
  end
end
