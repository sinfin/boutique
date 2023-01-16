$(document)
  .on('boutiqueOrdersEditSubscriptionFieldsRecurringChanged', (e, checkbox) => {
    const $form = $(checkbox).closest('form')
    const $agreement = $form.find('.b-orders-edit-recurring-payment-agreement')
    const $input = $agreement.find('input')

    if (checkbox.checked) {
      $input.prop('disabled', false)
      $agreement.show()
    } else {
      $input.prop('disabled', true)
      $agreement.hide()
    }
  })
