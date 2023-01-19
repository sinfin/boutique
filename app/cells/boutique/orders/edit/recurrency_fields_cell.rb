# frozen_string_literal: true

class Boutique::Orders::Edit::RecurrencyFieldsCell < ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def show
    render if model.object.line_items.present? && model.object.line_items.any? do |line_item|
      line_item.product.subscription?
    end
  end

  def collection
    [
      [true, t(".title_true"), true_title],
      [false, t(".title_false"), "<p>#{t(".text_false")}</p>"],
    ]
  end

  def true_title
    Boutique.config
            .orders_edit_recurrency_title_proc
            .call(context: self,
                  current_site:,
                  price: model.object.total_price,
                  product: model.object.line_items.first.product)
  end
end