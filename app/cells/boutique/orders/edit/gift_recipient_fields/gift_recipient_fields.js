$(document)
  .on('change', '.b-orders-edit-gift-fields__gift-checkbox', (e) => {
    const gift = e.currentTarget.checked;

    // show with gift enabled
    $('.b-orders-edit-gift-fields__fields, \
       .b-orders-edit__gift-recipient-address-fields, \
       .b-orders-edit__addresses-fields-title--gift').toggle(gift)

    $('.b-orders-edit-gift-fields__fields, \
       .b-orders-edit__gift-recipient-address-fields').find('input, select')
                                                      .prop('disabled', !gift)

    // hide with gift enabled
    $('.f-addresses-fields__fields-wrap--primary-address, \
       .b-orders-edit__addresses-fields-title--default').toggle(!gift)

    $('.f-addresses-fields__fields-wrap--primary-address').find('input, select')
                                                          .prop('disabled', gift)
  })
