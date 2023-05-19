$(document)
  .on('change', '.b-orders-cart-gift-fields__gift-checkbox', (e) => {
    var gift = e.currentTarget.checked;

    // show with gift enabled
    $('.b-orders-cart-gift-fields__fields, \
       .b-orders-cart__addresses-fields-title--gift').toggle(gift)

    $('.b-orders-cart-gift-fields__fields').find('input, select')
                                           .prop('disabled', !gift)

    // hide with gift enabled
    $('.b-orders-cart__addresses-fields-title--default').toggle(!gift)
  })
