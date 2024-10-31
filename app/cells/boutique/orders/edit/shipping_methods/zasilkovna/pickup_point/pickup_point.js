(() => {
  const $btn = $('.b-orders-edit-shipping-methods-zasilkovna-pickup-point__btn')

  if ($btn.length == 0) {
    return
  }

  const $modal = $('.b-orders-edit-shipping-methods-zasilkovna-pickup-point__modal')
  const $wrap = $('.b-orders-edit-shipping-methods-zasilkovna-pickup-point')

  const callback = (point) => {
    $modal.removeClass('b-orders-edit-shipping-methods-zasilkovna-pickup-point__modal--visible')
    $('html').removeClass('b--no-scroll')

    if (!point) {
      return;
    }

    const title = `${point['place']}, ${point['street']}, ${point['city']} ${point['zip']}`
    $wrap.find('.b-orders-edit-shipping-methods-zasilkovna-pickup-point__input-remote-id')
         .val(point['id'])
    $wrap.find('.b-orders-edit-shipping-methods-zasilkovna-pickup-point__input-title')
         .val(title)
    $wrap.find('.b-orders-edit-shipping-methods-zasilkovna-pickup-point__selected')
         .text(title)
    $wrap.find('.b-orders-edit-shipping-methods-zasilkovna-pickup-point__error')
         .remove()
  };

  $btn.on('click', () => {
    const apiKey = $(this).data('api-key')

    const opts = {
      language: 'cs',
      country: 'cz',
    }

    $modal.addClass('b-orders-edit-shipping-methods-zasilkovna-pickup-point__modal--visible')
    $('html').addClass('b--no-scroll')

    Packeta.Widget.pick(apiKey, callback, opts, $modal[0])
  });
})()
