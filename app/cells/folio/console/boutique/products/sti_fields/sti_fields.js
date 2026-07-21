$(document).on('change', '.f-c-b-products-sti-fields__type-input', function () {
  const type = $(this).val()
  const $inputs = $('.f-c-b-products-sti-fields__inputs')
  $inputs.hide()
  $inputs.filter(`[data-type=${type}]`).show()
})

$(document).on('change', '.f-c-b-products-sti-fields__intro-checkbox', function () {
  $(this)
    .closest('.f-c-b-products-sti-fields__intro')
    .toggleClass('f-c-b-products-sti-fields__intro--active', this.checked)
})
