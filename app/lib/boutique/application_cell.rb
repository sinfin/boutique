# frozen_string_literal: true

class Boutique::ApplicationCell < Folio::ApplicationCell
  include Boutique::PriceHelper

  def current_order
    controller.current_order
  end
end
