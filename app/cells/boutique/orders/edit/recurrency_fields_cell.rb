# frozen_string_literal: true

class Boutique::Orders::Edit::RecurrencyFieldsCell < ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def show
    render if model.object.line_items.present? && model.object.line_items.any? do |line_item|
      line_item.product.subscription? && line_item.product.has_subscription_frequency?
    end
  end

  def collection
    [
      [true, t(".title_true"), true_title],
      [false, t(".title_false"), "<p>#{t(".text_false")}</p>"],
    ]
  end

  def true_title
    current_site.recurring_payment_disclaimer
                .gsub("{AMOUNT}", model.object.total_price.to_s)
  end
end
