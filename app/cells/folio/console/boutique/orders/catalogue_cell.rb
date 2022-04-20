# frozen_string_literal: true

class Folio::Console::Boutique::Orders::CatalogueCell < Folio::ConsoleCell
  include Folio::Console::IndexHelper

  def show
    @klass = Boutique::Order
    render
  end
end
