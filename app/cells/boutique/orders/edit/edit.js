(() => {
  const refresh = (e) => {
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
        shipping_method_id: $wrap.find('.b-orders-edit-shipping-methods__option-input:checked').val(),
        country_code: e.currentTarget.value,
      },
      success: (res) => {
        if (res && res.data) {
          $wrap.find('.b-orders-edit-sidebar-bottom').replaceWith(res.data.sidebarBottom)
          $wrap.find('.b-orders-payment-methods-price').replaceWith(res.data.price)
          // $wrap.find('.b-orders-edit-shipping-methods').replaceWith(res.data.shippingMethods)

          $wrap
            .find('.b-orders-edit-voucher-fields')
            .trigger('updatePrice', [res.data.voucherFields])
        }

        $wrap.removeClass('b-orders-edit--refreshing')
      },
      error: () => {
        // TODO @dedekm - what should be done if the load fails? Reloading the page for now
        window.location.reload()
      }
    })
  }

  $(document)
    .on('change', '.b-orders-edit .f-addresses-fields__fields-wrap--primary-address .f-addresses-fields__country-code-input', refresh)
    .on('change', '.b-orders-edit .b-orders-edit-shipping-methods__option-input', refresh)
})()
