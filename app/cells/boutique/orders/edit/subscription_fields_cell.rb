# frozen_string_literal: true

class Boutique::Orders::Edit::SubscriptionFieldsCell < Boutique::ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def show
    render if show_subscription_starts_at_input? || show_subscription_recurring_input?
  end

  def line_item
    model.object.line_items.first
  end

  def show_subscription_starts_at_input?
    @show_subscription_starts_at_input ||= line_item.product.has_subscription_frequency?
  end

  def show_subscription_recurring_input?
    @show_subscription_recurring_input ||= line_item.product.subscription_recurrent_payment_enabled?
  end

  def subscription_starts_at_input(g)
    collection = g.object.subscription_starts_at_options_for_select
    selected = g.object.subscription_starts_at.try(:to_date)
    selected = nil if collection.none? { |o| o.last == selected }

    g.input(:subscription_starts_at, collection:,
                                     selected:,
                                     include_blank: false,
                                     label: false,
                                     wrapper: false,
                                     input_html: { class: "b-orders-edit-subscription-fields__input" })
  end

  def subscription_recurring_checked(g)
    return true if g.object.subscription_recurring.nil?

    g.object.subscription_recurring
  end
end
