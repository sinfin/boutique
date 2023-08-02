const bof_form = document.querySelector('.f-c-b-order-refunds-form')
if (bof_form) {
  const from_date_input = bof_form.querySelector('.order_refund_subscription_refund_from input')
  const to_date_input = bof_form.querySelector('.order_refund_subscription_refund_to input')
  const subscriptions_price_input = bof_form.querySelector('.order_refund_subscriptions_price input')
  const total_price_input = bof_form.querySelector('.order_refund_total_price input')
  const minimal_subscription_date = new Date(from_date_input.dataset.minDate)
  const maximal_subscription_date = new Date(to_date_input.dataset.maxDate)

  function updatePrices() {

    var from = new Date(reformatDateString(from_date_input.value))
    if (from < minimal_subscription_date || from > maximal_subscription_date) {
      from = minimal_subscription_date
      from_date_input.classList.add("is-invalid")
    }
    else {
      from_date_input.classList.remove("is-invalid")
    }

    var to = new Date(reformatDateString(to_date_input.value))
    if (to > maximal_subscription_date || to < minimal_subscription_date) {
      to = maximal_subscription_date
      to_date_input.classList.add("is-invalid")
    }
    else {
      to_date_input.classList.remove("is-invalid")
    }

    const days = Math.ceil((to - from) / (1000 * 60 * 60 * 24))
    var price = ((days * Number(subscriptions_price_input.dataset.pricePerDayInCents)) / 100).toFixed(2)
    if (from_date_input.classList.contains("is-invalid") || to_date_input.classList.contains("is-invalid")) {
      price = 0.0
    }

    subscriptions_price_input.value = price
    total_price_input.value = price
  }

  function reformatDateString(date_str) { // 01.08.2020 -> 2020-08-01
    const date_arr = date_str.split(". ")
    return date_arr[2] + "-" + date_arr[1] + "-" + date_arr[0]
  }

  from_date_input.addEventListener("change", updatePrices)
  to_date_input.addEventListener("change", updatePrices)
}
