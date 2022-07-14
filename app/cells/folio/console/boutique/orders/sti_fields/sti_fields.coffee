$(document).on "change", ".f-c-b-orders-sti-fields__type-input", ->
  type = $(this).val()

  $inputs = $(".f-c-b-orders-sti-fields__inputs")
  $inputs.hide()
  $inputs.filter("[data-type=#{type}]").show()
