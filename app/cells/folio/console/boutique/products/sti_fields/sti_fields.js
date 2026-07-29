$(document).on('change', '.f-c-b-products-sti-fields__type-input', function () {
  $(document).trigger('folioConsoleBoutiqueProductTypeChange', [$(this).val()])
})

$(document).on('folioConsoleBoutiqueProductTypeChange', function (e, type) {
  const $fields = $('[data-boutique-product-type]')
  $fields.hide()
  $fields.filter(`[data-boutique-product-type="${type}"]`).show()
})
