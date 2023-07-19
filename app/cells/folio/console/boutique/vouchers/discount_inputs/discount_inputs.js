window.Folio.Stimulus.register('f-c-b-vouchers-discount-inputs', class extends window.Stimulus.Controller {
  static targets = ['regularHint', 'percentageHint', 'input']

  onCheckboxChange (e) {
    const checked = e.currentTarget.checked

    if (checked) {
      this.regularHintTarget.hidden = true
      this.percentageHintTarget.hidden = false
      this.inputTarget.max = "100"

      const value = parseInt(this.inputTarget.value)

      if (value && value > 100) {
        this.inputTarget.value = 100
      }
    } else {
      this.regularHintTarget.hidden = false
      this.percentageHintTarget.hidden = true
      this.inputTarget.removeAttribute('max')
    }
  }
})
