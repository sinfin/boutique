$(document)
  .on('change', '.b-orders-edit-recurrency-fields__option-input', (e) => {
    const subscriptionRecurring = e.currentTarget.value === "true" && e.currentTarget.checked

    $(e.currentTarget)
      .closest('form')
      .trigger('boutiqueSubscriptionRecurringChange', subscriptionRecurring)
  })
