# frozen_string_literal: true

# Wording for the console - an order or a subscription bought with an
# introductory price has to say so, including whether the introductory period
# is still running.
module Folio::Console::Boutique::IntroHelper
  def console_intro_line_item(order)
    order.line_items.detect { |line_item| line_item.subscription? && line_item.intro? }
  end

  # "zdarma po dobu 2 měsíců, poté 149 Kč"
  def console_intro_label(line_item)
    intro_price = if line_item.free_intro?
      t("folio.console.boutique.intro.free")
    else
      price(line_item.unit_price)
    end

    t("folio.console.boutique.intro.label",
      price: intro_price,
      count: line_item.intro_duration_months,
      subsequent_price: price(line_item.subsequent_unit_price))
  end

  # "Trial do 28. 9. 2026", nil for a subscription bought for the full price
  def console_subscription_intro_label(subscription)
    line_item = subscription.original_line_item
    return if line_item.nil? || !line_item.intro?
    return if subscription.intro_until.nil?

    kind = line_item.free_intro? ? "trial" : "discounted"
    state = subscription.intro_active? ? "active" : "over"

    t("folio.console.boutique.intro.subscription.#{kind}.#{state}",
      date: l(subscription.intro_until.to_date, format: :short))
  end
end
