let success = false

const voucherRequestSuccess = ($wrap, res) => {
  if (res && res.data) {
    success = true

    const $oldEdit = $wrap.closest('.b-orders-edit')
    const $newEdit = $(res.data)

    const $oldCovers = $oldEdit.find('.b-orders-edit-summary__line-item-cover-wrap').detach()

    const selectors = [
      'input[name="authenticity_token"]',
      '.b-orders-edit-voucher-fields',
      '.b-orders-edit-sidebar__ajax-replacable',
      '.b-orders-edit-summary',
      '.b-orders-edit-recurrency-fields',
      '.b-orders-edit__payment'
    ]

    selectors.forEach((selector) => {
      $oldEdit.find(selector).replaceWith($newEdit.find(selector))
    })

    const $newCovers = $('.b-orders-edit-summary__line-item-cover-wrap')

    $oldCovers.each((_, oldCover) => {
      const $newCover = $newCovers.filter((_, newCover) => newCover.dataset.lineItem === oldCover.dataset.lineItem)

      if ($newCover.length) {
        $newCover.replaceWith(oldCover)
      }
    })

    window.updateAllFolioLazyLoadInstances()
  }
}

const voucherRequestComplete = ($wrap) => {
  if (success) return

  const $group = $wrap.find('.form-group')

  $group
    .find('.invalid-feedback')
    .remove()

  $group
    .addClass('form-group-invalid')
    .find('.form-control')
    .addClass('is-invalid')
    .after(`<div class="invalid-feedback">${$trigger.data('error')}</div>`)

  $wrap.removeClass('b-orders-edit-voucher-fields--loading')
}

$(document)
  .on('click', '.b-orders-edit-voucher-fields__apply', (e) => {
    e.preventDefault()

    const $trigger = $(e.currentTarget)
    const $wrap = $trigger.closest('.b-orders-edit-voucher-fields')

    if ($wrap.hasClass('b-orders-edit-voucher-fields--loading')) return

    $wrap.addClass('b-orders-edit-voucher-fields--loading')

    success = false

    $.ajax({
      url: $trigger.data('url'),
      method: 'POST',
      data: {
        voucher_code: $wrap.find('.b-orders-edit-voucher-fields__input').val()
      },
      success: (res) => voucherRequestSuccess($wrap, res),
      complete: () => voucherRequestComplete($wrap),
    })
  })
  .on('updatePrice', '.b-orders-edit-voucher-fields', (e, res) => {
    const $price = $(e.target).find('.b-orders-edit-voucher-fields__price')
    const newPriceHTML = $(res).find('.b-orders-edit-voucher-fields__price').html()

    $price.html(newPriceHTML)
  })
