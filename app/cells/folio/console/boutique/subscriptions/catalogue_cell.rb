# frozen_string_literal: true

class Folio::Console::Boutique::Subscriptions::CatalogueCell < Folio::ConsoleCell
  include Folio::Console::IndexHelper

  def show
    @klass = Boutique::Subscription
    render
  end
end
