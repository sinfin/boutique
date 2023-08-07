# frozen_string_literal: true

require "test_helper"

module Boutique
  class PaymentTest < ActiveSupport::TestCase
    test "failed pay of order" do
      order = create(:boutique_order, :confirmed)
      payment = order.payments.create!(remote_id: "123", payment_gateway_provider: "go_pay")
      assert payment.pending?

      order.pay!

      exp = assert_raises(StandardError) do
        payment.pay!
      end

      assert payment.reload.paid?
      assert_equal "Order #{order.id} is in state #{order.aasm_state} and cannot be paid by payment ##{payment.id}!", exp.message
    end
  end
end
