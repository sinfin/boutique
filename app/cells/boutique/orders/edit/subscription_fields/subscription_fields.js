$(document)
  .on('change', '.b-orders-edit-subscription-fields__recurring-checkbox', (e) => {
    $(e.currentTarget)
      .closest('form')
      .trigger('boutiqueOrdersEditSubscriptionFieldsRecurringChanged', e.currentTarget)
  })
