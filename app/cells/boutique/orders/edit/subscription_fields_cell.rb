# frozen_string_literal: true

class Boutique::Orders::Edit::SubscriptionFieldsCell < Boutique::ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def subscription_starts_at_input(g)
    collection = g.object.subscription_starts_at_options_for_select
    selected = g.object.subscription_starts_at.try(:to_date)
    selected = nil if collection.none? { |o| o.last == selected }

    g.input(:subscription_starts_at, collection:,
                                     selected:,
                                     include_blank: false)
  end

  def subscription_recurring_checked(g)
    return true if g.object.subscription_recurring.nil?

    g.object.subscription_recurring
  end
end
