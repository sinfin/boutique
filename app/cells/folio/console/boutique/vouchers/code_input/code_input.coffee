$(document).on "change", ".f-c-b-vouchers-code-input__code-type-input", ->
  type = $(this).val()

  $inputs = $(".f-c-b-vouchers-code-input__code-input-group")
  $inputs.hide()
  $inputs.filter("[data-type=#{type}]").show()
