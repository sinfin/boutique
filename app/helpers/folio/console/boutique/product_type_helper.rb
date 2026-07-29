# frozen_string_literal: true

module Folio::Console::Boutique::ProductTypeHelper
  # Marks console inputs that only belong to one of the product types. The STI
  # type select of the product form shows and hides every marked element on the
  # page, so they do not have to sit anywhere near the select - see
  # folio/console/boutique/products/sti_fields/sti_fields.js.
  #
  # The element keeps the class of the cell it belongs to, only the behaviour
  # comes from here.
  def console_product_type_attributes(product, type)
    {
      "data-boutique-product-type" => type,
      "style" => ("display: none" unless product.type == type),
    }.compact
  end
end
