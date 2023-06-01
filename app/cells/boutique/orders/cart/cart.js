$(document)
  .on('change', '.b-orders-cart .f-addresses-fields__fields-wrap--primary-address .f-addresses-fields__country-code-input', (e) => {
    const $wrap = $(e.currentTarget).closest('.b-orders-cart')

    if ($wrap.hasClass('b-orders-cart--refreshing')) {
      e.preventDefault()
      return
    }

    $wrap.addClass('b-orders-cart--refreshing')

    $.ajax({
      method: "GET",
      url: $wrap.data('refreshedUrl'),
      data: {
        country_code: e.currentTarget.value,
      },
      success: (res) => {
        if (res && res.data) {
          $wrap.find('.b-orders-summary').replaceWith(res.data.summary)
          $wrap.find('.b-orders-payment-methods-price').replaceWith(res.data.price)
        }
        const $res = $(res)
        $wrap.removeClass('b-orders-cart--refreshing')
      },
      error: () => {
        // TODO @dedekm - what should be done if the load fails? Reloading the page for now
        window.location.reload()
      }
    })
  })
