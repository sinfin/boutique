# frozen_string_literal: true

require "test_helper"

class Boutique::OrderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "revert_cancelation event returns order to correct state" do
    order = create(:boutique_order, :ready_to_be_confirmed)

    {
      confirm: "confirmed",
      pay: "paid",
      dispatch: "dispatched",
    }.each do |event, state|
      order.aasm.fire!(event)
      assert_equal state, order.aasm_state

      order.cancel!
      assert_equal "cancelled", order.aasm_state
      assert order.cancelled_at

      order.revert_cancelation!
      assert_equal state, order.aasm_state
      assert_nil order.cancelled_at
    end
  end

  test "confirm" do
    order = create(:boutique_order, :ready_to_be_confirmed)

    assert_nil order.read_attribute(:line_items_price)
    assert_nil order.read_attribute(:shipping_method_price)
    assert_nil order.read_attribute(:payment_method_price)
    assert_nil order.read_attribute(:total_price)

    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      perform_enqueued_jobs do
        order.confirm!
      end
    end

    assert order.read_attribute(:line_items_price)
    assert order.read_attribute(:shipping_method_price)
    assert order.read_attribute(:payment_method_price)
    assert order.read_attribute(:total_price)
  end

  test "pay" do
    order = create(:boutique_order, :confirmed)

    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      perform_enqueued_jobs do
        order.pay!
      end
    end
  end


  test "dispatch" do
    order = create(:boutique_order, :paid)

    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      perform_enqueued_jobs do
        order.dispatch!
      end
    end
  end

  test "order numbers" do
    Boutique::Order.connection.execute("ALTER SEQUENCE boutique_orders_base_number_seq RESTART;")

    travel_to Time.zone.local(2022, 1, 1)
    order = create(:boutique_order, :ready_to_be_confirmed)
    assert_nil order.number

    order.confirm!
    assert_equal "2200001", order.number

    travel_to Time.zone.local(2023, 1, 1)
    order = create(:boutique_order, :confirmed)
    assert_equal "2300002", order.number
  end

  test "digital_only order shouldn't validate address" do
    order = create(:boutique_order, :ready_to_be_confirmed)

    assert order.primary_address.present?
    assert order.valid?

    order = create(:boutique_order, :ready_to_be_confirmed, digital_only: true)

    assert_not order.primary_address.present?
    assert order.valid?
  end
end
