# frozen_string_literal: true

class Boutique::Orders::PaymentRedirectCell < ApplicationCell
  def show
    render if model.present?
  end

  def text
    t(".text_html", link: link_to(t(".link"), model))
  end
end
