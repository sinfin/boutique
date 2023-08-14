# frozen_string_literal: true

class Boutique::Orders::Edit::VoucherFieldsCell < Boutique::ApplicationCell
  class_name "b-orders-edit-voucher-fields", :applied?

  def input
    return unless model.present?

    model.input :voucher_code, label: t(".label"),
                               input_html: { class: "b-orders-edit-voucher-fields__input" },
                               wrapper_html: { class: "b-orders-edit-voucher-fields__group" }
  end

  def applied?
    order.voucher.present?
  end

  def order
    options[:order] || model.object
  end
end
