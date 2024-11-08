(() => {
  const callback = (point) => {
    const $modal = $('.b-shipping-methods-zasilkovna-pickup-point__modal')
    $modal.removeClass('b-shipping-methods-zasilkovna-pickup-point__modal--visible')
    $('html').removeClass('b--no-scroll')

    if (!point) {
      return;
    }

    const $wrap = $('.b-shipping-methods-zasilkovna-pickup-point')
    const title = `${point['place']}, ${point['street']}, ${point['city']} ${point['zip']}`

    $wrap.find('.b-shipping-methods-zasilkovna-pickup-point__input-id')
         .val(point['id'])
    $wrap.find('.b-shipping-methods-zasilkovna-pickup-point__input-country-code')
         .val(point['country'])
         .change()
    $wrap.find('.b-shipping-methods-zasilkovna-pickup-point__input-title')
         .val(title)
    $wrap.find('.b-shipping-methods-zasilkovna-pickup-point__selected')
         .text(title)
    $wrap.find('.b-shipping-methods-zasilkovna-pickup-point__error')
         .remove()
  };

  $(document).on('click', '.b-shipping-methods-zasilkovna-pickup-point__btn', (e) => {
    const apiKey = $(e.target).data('api-key')

    const opts = {
      language: 'cs',
      country: 'cz,sk',
    }

    const $modal = $('.b-shipping-methods-zasilkovna-pickup-point__modal')
    $modal.addClass('b-shipping-methods-zasilkovna-pickup-point__modal--visible')
    $('html').addClass('b--no-scroll')

    Packeta.Widget.pick(apiKey, callback, opts, $modal[0])
  });
})()
