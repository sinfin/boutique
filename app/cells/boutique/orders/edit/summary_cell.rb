# frozen_string_literal: true

class Boutique::Orders::Edit::SummaryCell < Boutique::ApplicationCell
  THUMB_SIZE = "50x50#"

  def line_items
    @line_items ||= model.object.line_items.includes(product_variant: { product: { cover_placement: :file } }).load
  end

  def product_variant_select_for(f, line_item)
    f.simple_fields_for :line_items, line_item do |subfields|
      subfields.association(:product_variant, collection: line_item.product.variants,
                                              include_blank: false,
                                              label: false).html_safe
    end
  end

  def subscription_period(line_item)
    label = t(".subscription_period.months", count: line_item.subscription_period)

    if model.renewed_subscription.present?
      date = l(model.renewed_subscription.active_until + 1.day, format: :as_date)
      label += ", #{t(".subscription_period.from", date:)}"
    end

    label
  end
end
