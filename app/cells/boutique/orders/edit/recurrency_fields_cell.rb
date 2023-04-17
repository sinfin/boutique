# frozen_string_literal: true

class Boutique::Orders::Edit::RecurrencyFieldsCell < ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def show
    render if model.object.recurrent_payment_available? && model.object.line_items.any? do |line_item|
      line_item.requires_subscription_recurring?
    end
  end

  def collection
    [
      [true, t(".title_true"), true_title],
      [false, t(".title_false"), "<p>#{t(".text_false")}</p>"],
    ]
  end

  def text_true
    Boutique.config
            .orders_edit_recurrency_title_proc
            .call(context: self,
                  current_site:,
                  period: model.object.subscription_period_to_human,
                  price: model.object.total_price,
                  product: model.object.line_items.first.product)
  end

  def show_error_message?
    model.object.errors && model.object.errors.where(:line_items, :missing_subscription_recurring).present?
  end
end
