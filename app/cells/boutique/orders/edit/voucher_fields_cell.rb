# frozen_string_literal: true

class Boutique::Orders::Edit::VoucherFieldsCell < ApplicationCell
  def input
    model.input :voucher_code, label: t(".label"),
                               input_html: { class: "b-orders-edit-voucher-fields__input" }
  end
end
