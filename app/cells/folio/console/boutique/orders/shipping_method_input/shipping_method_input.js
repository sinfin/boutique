$(document).on('change', '.f-c-b-orders-shipping-method-input__select', function () {
  const id = parseInt($(this).val(), 10)

  $('.f-c-b-orders-shipping-method-input__additional-input').each(function (i, element) {
    const $element = $(element)
    const ids = $element.data('ids')

    if(ids.includes(id)) {
      $element.show()
    } else {
      $element.hide()
    }
  });
})
