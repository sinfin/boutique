# frozen_string_literal: true

Folio::Console::BaseController.class_eval do
  helper Folio::Engine.helpers
  helper Boutique::Engine.helpers
end
