# frozen_string_literal: true

module Boutique::SubscriptionHelper
  include ActionView::Helpers::NumberHelper

  def recurrence_to_human(months)
    I18n.t("recurrence.months", count: months)
  end

  def duration_to_human(months)
    I18n.t("duration.months", count: months)
  end
end
