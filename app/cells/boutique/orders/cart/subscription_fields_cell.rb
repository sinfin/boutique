# frozen_string_literal: true

class Boutique::Orders::Cart::SubscriptionFieldsCell < Boutique::ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def show
    render if show_subscription_starts_at_input?
  end

  def line_item
    model.object.line_items.first
  end

  def show_subscription_starts_at_input?
    @show_subscription_starts_at_input ||= line_item.product.has_subscription_frequency?
  end

  def subscription_starts_at_input(g)
    collection = g.object.subscription_starts_at_options_for_select
    selected = g.object.subscription_starts_at.try(:to_date)
    selected = nil if collection.none? { |o| o.last == selected }

    g.input(:subscription_starts_at, collection:,
                                     selected:,
                                     include_blank: false,
                                     label: false,
                                     wrapper_html: { class: "mb-0" },
                                     input_html: { class: "b-orders-cart-subscription-fields__input" })
  end
end
