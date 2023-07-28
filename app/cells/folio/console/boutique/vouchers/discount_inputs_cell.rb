# frozen_string_literal: true

class Folio::Console::Boutique::Vouchers::DiscountInputsCell < Folio::ConsoleCell
  def discount_input_html
    {
      "min" => 1,
      "data-f-c-b-vouchers-discount-inputs-target" => "input",
    }
  end

  def checkbox_input_html
    {
      "data-f-c-b-vouchers-discount-inputs-target" => "checkbox",
      "data-action" => "f-c-b-vouchers-discount-inputs#onCheckboxChange",
    }
  end
end
