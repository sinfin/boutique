$(document).on('change', '.f-c-b-products-intro-fields__checkbox', function () {
  $(this)
    .closest('.f-c-b-products-intro-fields')
    .toggleClass('f-c-b-products-intro-fields--active', this.checked)
})
