$(document)
  .on('change', '.f-c-b-subscriptions-form__product-variant-input', (e) => {
    const address = $(e.target).find("option:selected").data('requires-address');

    const $addressFields = $('.f-c-b-subscriptions-form__address-fields')

    if (address) {
      $addressFields.show();
      $addressFields.find('input').prop('disabled', false);
    } else {
      $addressFields.hide();
      $addressFields.find('input').prop('disabled', true);
    }
  })
