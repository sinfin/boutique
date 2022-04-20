# frozen_string_literal: true

Folio::ApplicationCell.class_eval do
  self.view_paths << "#{Boutique::Engine.root}/app/cells"

  include Boutique::PriceHelper
end
