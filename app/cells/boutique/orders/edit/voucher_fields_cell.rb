# frozen_string_literal: true

class Boutique::Orders::Edit::VoucherFieldsCell < ApplicationCell
  class_name "b-orders-edit-voucher-fields", :applied?

  def input
    model.input :voucher_code, label: t(".label"),
                               input_html: { class: "b-orders-edit-voucher-fields__input" },
                               wrapper_html: { class: "b-orders-edit-voucher-fields__group" }
  end

  def applied?
    model.object.voucher.present?
  end
end
