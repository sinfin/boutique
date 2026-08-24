(() => {
  const refresh = (e) => {
    const $wrap = $(e.currentTarget).closest('.b-orders-cart')

    if ($wrap.hasClass('b-orders-cart--refreshing')) {
      e.preventDefault()
      return
    }

    $wrap.addClass('b-orders-cart--refreshing')

    const isRecurring = $wrap.find('.b-orders-cart-recurrency-fields__option-input').prop('checked')

    $.ajax({
      method: 'GET',
      url: $wrap.data('refreshedUrl'),
      data: {
        shipping_method_id: $wrap.find('.b-checkout-cart-shipping-methods__option-input:checked').val(),
        country_code: $wrap.find('.f-addresses-fields__fields-wrap--primary-address .f-addresses-fields__country-code-input').val(),
        subscription_recurring: isRecurring,
        subscription_period: isRecurring ? null : $wrap.find('.b-orders-cart-recurrency-fields__nonrecurring-payment-option-input:checked:not(:disabled)').val(),
        boutique_product_variant_id: $wrap.find('[data-boutique-product-variant-input]').val()
      },
      success: (res) => {
        if (res && res.data) {
          $wrap.find('.b-orders-summary').replaceWith(res.data.summary)
          $wrap.find('.b-orders-payment-methods-price').replaceWith(res.data.price)

          // Hosts that add their own fragments through
          // refreshed_cart_fragments_proc swap them in from here. Native
          // CustomEvent rather than a jQuery trigger, so Stimulus controllers
          // can bind it with a plain data-action.
          $wrap[0].dispatchEvent(new CustomEvent('boutique:cart-refreshed', {
            bubbles: true,
            detail: res.data
          }))
        }
        const $res = $(res)
        $wrap.removeClass('b-orders-cart--refreshing')
      },
      error: () => {
        // TODO @dedekm - what should be done if the load fails? Reloading the page for now
        window.location.reload()
      }
    })
  }

  $(document)
    .on('change', '.b-orders-cart .f-addresses-fields__fields-wrap--primary-address .f-addresses-fields__country-code-input', refresh)
    .on('change', '.b-orders-cart .b-checkout-cart-shipping-methods__option-input', refresh)
    .on('boutiqueSubscriptionRecurringCheckboxesUpdated', '.b-orders-cart__form', refresh)
})()
