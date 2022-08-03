$(document).on('change', '.f-c-b-vouchers-code-input__code-type-input', function () {
  const type = $(this).val()
  const $inputs = $('.f-c-b-vouchers-code-input__code-input-group')
  $inputs.hide()
  $inputs.filter(`[data-type=${type}]`).show()
})
