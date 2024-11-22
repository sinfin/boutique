# frozen_string_literal: true

class Boutique::Orders::Edit::LineItemsFieldsCell < ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def show
    render if render_product_variant_input? || render_amount_input?
  end

  def line_item
    @line_item ||= model.object.line_items.first
  end

  def render_product_variant_input?
    return @render_product_variant_input unless @render_product_variant_input.nil?

    @render_product_variant_input = line_item.product.variants.size > 1
  end

  def render_amount_input?
    return @render_amount_input unless @render_amount_input.nil?

    @render_amount_input = line_item.product.max_purchase_amount_allowed.nil? || line_item.product.max_purchase_amount_allowed > 1
  end
end
