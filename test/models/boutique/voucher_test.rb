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

  test "product_variant_code" do
    product_1 = create(:boutique_product)
    product_2 = create(:boutique_product)

    voucher = create(:boutique_voucher)
    assert voucher.applicable_for?(product_1)
    assert voucher.applicable_for?(product_2)

    voucher.products = [product_1]
    assert voucher.applicable_for?(product_1)
    assert_not voucher.applicable_for?(product_2)

    voucher.products = [product_1, product_2]
    assert voucher.applicable_for?(product_1)
    assert voucher.applicable_for?(product_2)
  end
end
