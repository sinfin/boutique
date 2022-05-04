# frozen_string_literal: true

class Boutique::Orders::Edit::SubscriptionFieldsCell < Boutique::ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor

  def subscription_starts_at_options_for_select
    start = Date.today.beginning_of_month
    12.times.map do |n|
      date = start + n.months
      [I18n.l(date, format: :month_and_year), date]
    end
  end

  def subscription_recurring_checked(g)
    return true if g.object.subscription_recurring.nil?

    g.object.subscription_recurring
  end
end
