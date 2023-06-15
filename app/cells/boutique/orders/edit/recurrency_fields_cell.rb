# frozen_string_literal: true

class Boutique::Orders::Edit::RecurrencyFieldsCell < ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def show
    render if model.object.recurrent_payment_available? && model.object.line_items.any? do |line_item|
      line_item.requires_subscription_recurring?
    end
  end

  def collection
    @collection ||= begin
      c = [
        [true, t(".title_true"), true_title]
      ]

      unless model.object.recurrent_payment_enabled_by_default?
        c << [false, t(".title_false"), "<p>#{t(".text_false")}</p>"]
      end

      c
    end
  end

  def true_title
    @true_title ||= Boutique.config
                            .orders_edit_recurrency_title_proc
                            .call(context: self,
                                  current_site:,
                                  period: model.object.subscription_period_to_human,
                                  price: model.object.total_price,
                                  product: model.object.line_items.first.product)
  end

  def checked?(line_item, bool)
    line_item.subscription_recurring == bool || collection.size == 1
  end

  def show_error_message?
    model.object.errors && model.object.errors.where(:line_items, :missing_subscription_recurring).present?
  end
end
