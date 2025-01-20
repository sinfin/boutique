# frozen_string_literal: true

class Boutique::Orders::Edit::SummaryCell < Boutique::ApplicationCell
  THUMB_SIZE = "390x260"

  def line_items
    @line_items ||= model.line_items.includes(product_variant: { product: { cover_placement: :file } }).load
  end

  def subscription_period(line_item)
    label = t(".subscription_period.months", count: line_item.subscription_period)

    if model.renewed_subscription.present?
      date = l(model.renewed_subscription.active_until, format: :as_date)
      label += ", #{t(".subscription_period.from", date:)}"
    end

    label
  end
end
