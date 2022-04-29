# frozen_string_literal: true

class Boutique::Orders::Edit::SummaryCell < Boutique::ApplicationCell
  THUMB_SIZE = "390x260#"

  def line_items
    @line_items ||= model.line_items.includes(product_variant: { product: { cover_placement: :file } }).load
  end
end
