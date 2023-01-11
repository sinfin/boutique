$(document)
  .on('click', '.b-orders-edit-voucher-fields__apply', (e) => {
    e.preventDefault()

    const $trigger = $(e.currentTarget)
    const $wrap = $trigger.closest('.b-orders-edit-voucher-fields')

    if ($wrap.hasClass('b-orders-edit-voucher-fields--loading')) return

    $wrap.addClass('b-orders-edit-voucher-fields--loading')

    let success = false

    $.ajax({
      url: $trigger.data('url'),
      method: 'POST',
      data: {
        voucher_code: $wrap.find('.b-orders-edit-voucher-fields__input').val()
      },
      success: (res) => {
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
            '.b-orders-edit__payment'
          ]

          selectors.forEach((selector) => {
            $oldEdit.find(selector).replaceWith($newEdit.find(selector))
          })

          const $newCovers = $('.b-orders-edit-summary__line-item-cover-wrap')

          $oldCovers.each((i, oldCover) => {
            const $newCover = $newCovers.filter((i, newCover) => newCover.dataset.lineItem === oldCover.dataset.lineItem)

            if ($newCover.length) {
              $newCover.replaceWith(oldCover)
            }
          })

          window.updateAllFolioLazyLoadInstances()
        }
      },
      complete: () => {
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
    })
  })
