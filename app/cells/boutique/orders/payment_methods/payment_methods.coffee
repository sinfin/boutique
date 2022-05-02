$(document)
  .on 'click', '.b-orders-payment-methods__submit-btn', (e) ->
    e.preventDefault()
    $this = $(this)
    $form = $this.closest('form')
    $input = $form.find('.b-orders-payment-methods__hidden-method')
    $input.val($this.data('payment-method'))
    $form.submit()

$(document)
  .on 'turbolinks:load', ->
    $applePayButton = $('.b-orders-payment-methods__btns .btn[data-payment-method="APPLE_PAY"]')

    if $applePayButton.length > 0
      if window.ApplePaySession && window.ApplePaySession.canMakePayments()
        $applePayButton.show()
