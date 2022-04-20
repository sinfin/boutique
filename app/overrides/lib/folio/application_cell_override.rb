# frozen_string_literal: true

Folio::ApplicationCell.class_eval do
  self.view_paths << "#{Wipify::Engine.root}/app/cells"

  include Wipify::PriceHelper
end
