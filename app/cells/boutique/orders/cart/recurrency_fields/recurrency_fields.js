(() => {
  const BASE_CLASS = 'b-orders-cart-recurrency-fields'

  const uncheckOtherInputs = ($input) => {
    const $base = $input.closest(`.${BASE_CLASS}__inner`)

    const recurringSelector = `${BASE_CLASS}__option-input`
    const nonrecurringSelector = `${BASE_CLASS}__nonrecurring-payment-option-input`
    const $otherInputs = $base.find(`.${recurringSelector}, .${nonrecurringSelector}`).not($input)

    $otherInputs.prop('checked', false)
  }

  const onOptionInputChange = (e) => {
    const subscriptionRecurring = e.currentTarget.value === "true" && e.currentTarget.checked

    $(e.currentTarget)
      .closest('form')
      .trigger('boutiqueSubscriptionRecurringChange', subscriptionRecurring)

    uncheckOtherInputs($(e.target))
  }

  const onNonrecurringPaymentOptionInputChange = (e) => {
    uncheckOtherInputs($(e.target))
  }

  const onNonrecurringButtonClick = (e) => {
    const $base = $(e.target).closest(`.${BASE_CLASS}`)
    $base.addClass(`${BASE_CLASS}--nonrecurring-visible`)
  }

  $(document)
    .on('change', `.${BASE_CLASS}__option-input`, onOptionInputChange)
    .on('change', `.${BASE_CLASS}__nonrecurring-payment-option-input`, onNonrecurringPaymentOptionInputChange)
    .on('click', `.${BASE_CLASS}__show-nonrecurring-button`, onNonrecurringButtonClick)
})()
