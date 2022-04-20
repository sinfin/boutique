# frozen_string_literal: true

require "test_helper"

module Boutique
  class OrderMailerTest < ActionMailer::TestCase
    test "confirmed" do
      order = create(:boutique_order, email: "test@test.test")

      mail = OrderMailer.confirmed(order)
      assert_equal ["test@test.test"], mail.to
      assert_match "Hi", mail.body.encoded
    end

    test "paid" do
      order = create(:boutique_order, email: "test@test.test")

      mail = OrderMailer.paid(order)
      assert_equal ["test@test.test"], mail.to
      assert_match "Hi", mail.body.encoded
    end

    test "dispatched" do
      order = create(:boutique_order, email: "test@test.test")

      mail = OrderMailer.dispatched(order)
      assert_equal ["test@test.test"], mail.to
      assert_match "Hi", mail.body.encoded
    end
  end
end
