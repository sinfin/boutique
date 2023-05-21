# frozen_string_literal: true

class Boutique::Orders::Cart::RecurrencyFieldsCell < ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  class_name "b-orders-cart-recurrency-fields", :nonrecurring_visible?

  def show
    render if model.object.recurrent_payment_available? && model.object.line_items.any? do |line_item|
      line_item.requires_subscription_recurring?
    end
  end

  def nonrecurring_visible?
    params["nonrecurring_payment_visible"].present? || subscription_line_item.subscription_period.present?
  end

  def text_true
    @text_true ||= Boutique.config
                           .orders_edit_recurrency_title_proc
                           .call(context: self,
                                 current_site:,
                                 period: subscription_period_to_human,
                                 price: subscription_line_item.unit_price,
                                 product: subscription_line_item.product)
  end

  def subscription_line_item
    @subscription_line_item ||= model.object.subscription_line_item
  end

  def subscription_period_to_human
    case months = subscription_line_item.product_variant.subscription_period
    when 12
      I18n.t("datetime.each.year")
    else
      I18n.t("datetime.each.month", count: months)
    end
  end

  def show_error_message?
    model.object.errors && model.object.errors.where(:line_items, :missing_subscription_recurrence).present?
  end

  def nonrecurring_payment_option_input_class_name
    "b-orders-cart-recurrency-fields__nonrecurring-payment-option-input"
  end
end
