# frozen_string_literal: true

class Boutique::LineItems::SummaryCell < Boutique::ApplicationCell
  THUMB_SIZE = "150x100#"

  def line_items
    @line_items ||= model.includes(product_variant: { product: { cover_placement: :file } })
  end
end
