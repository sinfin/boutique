$(document)
  .on('change', '.b-orders-edit-gift-fields__gift-checkbox', (e) => {
    var gift = e.currentTarget.checked;

    // show with gift enabled
    $('.b-orders-edit-gift-fields__fields, \
       .b-orders-edit__addresses-fields-title--gift').toggle(gift)

    $('.b-orders-edit-gift-fields__fields').find('input, select')
                                           .prop('disabled', !gift)

    // hide with gift enabled
    $('.b-orders-edit__addresses-fields-title--default').toggle(!gift)
  })
