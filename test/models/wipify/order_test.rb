# frozen_string_literal: true

# == Schema Information
#
# Table name: wipify_orders
#
#  id                        :bigint           not null, primary key
#  customer_type             :string
#  customer_id               :bigint
#  base_number               :integer
#  number                    :string
#  email                     :string
#  aasm_state                :string           default("pending")
#  line_items_count          :integer          default(0)
#  line_items_price          :integer
#  shipping_method_price     :integer
#  payment_method_price      :integer
#  total_price               :integer
#  confirmed_at              :datetime
#  paid_at                   :datetime
#  dispatched_at             :datetime
#  cancelled_at              :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  wipify_shipping_method_id :bigint
#  wipify_payment_method_id  :bigint
#
require "test_helper"

class Wipify::OrderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "revert_cancelation event returns order to correct state" do
    order = create(:wipify_order, :ready_to_be_confirmed)

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
    order = create(:wipify_order, :ready_to_be_confirmed)

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
    order = create(:wipify_order, :confirmed)

    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      perform_enqueued_jobs do
        order.pay!
      end
    end
  end


  test "dispatch" do
    order = create(:wipify_order, :paid)

    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      perform_enqueued_jobs do
        order.dispatch!
      end
    end
  end

  test "order numbers" do
    Wipify::Order.connection.execute("ALTER SEQUENCE wipify_orders_base_number_seq RESTART;")

    travel_to Time.zone.local(2022, 1, 1)
    order = create(:wipify_order, :ready_to_be_confirmed)
    assert_nil order.number

    order.confirm!
    assert_equal "2200001", order.number

    travel_to Time.zone.local(2023, 1, 1)
    order = create(:wipify_order, :confirmed)
    assert_equal "2300002", order.number
  end
end
