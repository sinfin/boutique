# frozen_string_literal: true

class Boutique::Orders::Cart::VoucherFieldsCell < Boutique::ApplicationCell
  class_name "b-orders-cart-voucher-fields", :applied?

  def input
    model.input :voucher_code, label: t(".label"),
                               input_html: { class: "b-orders-cart-voucher-fields__input" },
                               wrapper_html: { class: "b-orders-cart-voucher-fields__group" }
  end

  def applied?
    model.object.voucher.present?
  end
end
