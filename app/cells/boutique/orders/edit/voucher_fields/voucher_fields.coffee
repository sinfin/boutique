bound = false

$(document)
  .on 'turbolinks:load', ->
    return bound = false unless $('.b-orders-edit-voucher-fields').length

    perform = ->
      $fields = $('.b-orders-edit-voucher-fields')
      return if $fields.hasClass('b-orders-edit-voucher-fields--loading')

      $fields.removeClass('b-orders-edit-voucher-fields--error')
      $fields.addClass('b-orders-edit-voucher-fields--loading')

      data = new FormData()
      data.append('voucher_code', '123456')

      console.log data

      $.ajax
        type: 'POST'
        url: $fields.find('.b-orders-edit-voucher-fields__button').data('url')
        data: data
        processData: false
        contentType: false
        success: (res) ->
          # TODO
          # $fields.closest('.b-orders-edit').replaceWith(res.html)
        error: ->
          # alert($fields.data('failure'))
        complete: ->
          $fields.removeClass('b-orders-edit-voucher-fields--loading')

    $(document)
      .on 'keypress.bOrdersEditVoucherFields', '.b-orders-edit-voucher-fields__input', (e) ->
        if e.key is 'Enter'
          e.preventDefault()
          e.stopPropagation()
          perform()
      .on 'click.bOrdersEditVoucherFields', '.b-orders-edit-voucher-fields__button', perform

  .on 'turbolinks:before-cache', ->
    return unless bound

    $(document)
      .off 'keypress.bOrdersEditVoucherFields'
      .off 'click.bOrdersEditVoucherFields'

    bound = false
