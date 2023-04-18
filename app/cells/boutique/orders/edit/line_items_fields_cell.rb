# frozen_string_literal: true

class Boutique::Orders::Edit::LineItemsFieldsCell < ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def show
    render if model.object.line_items.any? { |li| li.product.variants.size > 1 }
  end
end
