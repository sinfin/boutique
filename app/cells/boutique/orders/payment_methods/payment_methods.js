$(document)
  .on('click', '.b-orders-payment-methods__submit-btn', (e) => {
    e.preventDefault()

    const $this = $(e.target)
    const $form = $this.closest('form')
    const $input = $form.find('.b-orders-payment-methods__hidden-method')

    $input.val($this.data('payment-method'))
    $form.submit()
  })

  .on('turbolinks:load', () => {
    const $applePayButton = $('.b-orders-payment-methods__btns .btn[data-payment-method="APPLE_PAY"]')

    if ($applePayButton.length > 0) {
      if (window.ApplePaySession && window.ApplePaySession.canMakePayments()) {
        $applePayButton.show()
      }
    }
  })

  .on('boutiqueOrdersEditSubscriptionFieldsRecurringChanged', (e, checkbox) => {
    const $btns = $(checkbox).closest('form').find('.b-orders-payment-methods__submit-btn')

    if (checkbox.checked) {
      $btns.filter('[data-enabled-for-recurrent="false"]').prop('disabled', true)
    } else {
      $btns.prop('disabled', false)
    }
  })
