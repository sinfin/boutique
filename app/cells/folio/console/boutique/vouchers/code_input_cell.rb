# frozen_string_literal: true

class Folio::Console::Boutique::Vouchers::CodeInputCell < Folio::ConsoleCell
  include ActionView::Helpers::FormTagHelper

  def code_type_input
    collection = Boutique::Voucher::CODE_TYPES.map { |v| [t(".code_types.#{v}"), v] }

    model.input :code_type, collection:,
                            input_html: { class: "f-c-b-vouchers-code-input__code-type-input" },
                            include_blank: false,
                            hint: t(".hints.code_type")
  end
end
