# frozen_string_literal: true

class Folio::Console::Boutique::OrderRefunds::CatalogueCell < Folio::ConsoleCell
  include Folio::Console::IndexHelper

  def show
    @klass = Boutique::OrderRefund
    render
  end
end
