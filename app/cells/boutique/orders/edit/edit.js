$(document)
  .on('change', '.b-orders-edit .f-addresses-fields__country-code-input', (e) => {
    const $wrap = $(e.currentTarget).closest('.b-orders-edit')

    if ($wrap.hasClass('b-orders-edit--refreshing')) {
      e.preventDefault()
      return
    }

    $wrap.addClass('b-orders-edit--refreshing')

    $.ajax({
      method: "GET",
      url: $wrap.data('refreshedUrl'),
      data: {
        country_code: e.currentTarget.value,
      },
      success: (res) => {
        if (res && res.data) {
          $wrap.find('.b-orders-edit-sidebar-bottom').replaceWith(res.data.sidebarBottom)
          $wrap.find('.b-orders-payment-methods-price').replaceWith(res.data.price)
        }
        const $res = $(res)
        $wrap.removeClass('b-orders-edit--refreshing')
      },
      error: () => {
        // TODO @dedekm - what should be done if the load fails? Reloading the page for now
        window.location.reload()
      }
    })
  })
