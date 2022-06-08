# frozen_string_literal: true

require "test_helper"

class Boutique::VoucherTest < ActiveSupport::TestCase
  test "used_up?" do
    voucher = create(:boutique_voucher)
    assert_not voucher.used_up?

    voucher.update(number_of_allowed_uses: 1)
    assert_not voucher.used_up?

    voucher.use!
    assert voucher.used_up?
  end
end
