# frozen_string_literal: true

# Wording shared by the checkout sidebar and the payment methods heading - both
# have to spell out that the price shown is only introductory.
module Boutique::IntroHelper
  include Boutique::PriceHelper

  def intro_line_item_for(order)
    order.line_items.detect { |line_item| line_item.subscription? && line_item.intro? }
  end

  # "ZDARMA" / "39 Kč"
  def intro_price(line_item)
    if line_item.free_intro?
      t("boutique.intro.free_price")
    else
      price(line_item.unit_price)
    end
  end

  # "po dobu prvních 2 měsíců, poté 149 Kč měsíčně"
  def intro_note(line_item)
    t("boutique.intro.note_html",
      duration: t("boutique.intro.duration", count: line_item.intro_duration_months),
      price: content_tag(:strong, price(line_item.subsequent_unit_price)),
      frequency: intro_frequency(line_item))
  end

  private
    def intro_frequency(line_item)
      if line_item.subscription_period == 12
        t("boutique.intro.frequency.year")
      else
        t("boutique.intro.frequency.month", count: line_item.subscription_period)
      end
    end
end
