# frozen_string_literal: true

class Boutique::Orders::PaymentMethods::PriceCell < Boutique::ApplicationCell
  def intro_line_item
    return @intro_line_item if defined?(@intro_line_item)

    @intro_line_item = intro_line_item_for(model)
  end

  def title
    if model.zero_amount_authorization?
      t(".title_free")
    else
      t(".title", price: price(model.total_price))
    end
  end
end
