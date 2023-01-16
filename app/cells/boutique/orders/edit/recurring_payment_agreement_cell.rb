# frozen_string_literal: true

class Boutique::Orders::Edit::RecurringPaymentAgreementCell < Boutique::ApplicationCell
  def input
    model.input :recurring_payment_agreement,
                label: content_tag(:div, t(".label"), class: "small").html_safe,
                disabled: hidden?
  end

  def hidden?
    @hidden ||= model.object.line_items.none?(&:subscription_recurring?)
  end
end
