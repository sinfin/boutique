# frozen_string_literal: true

require "test_helper"

class Boutique::OrderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup_emails
    site = create(:folio_site)
    Rails.application.load_tasks
    Rake::Task["folio:email_templates:idp_seed"].execute

    Rails.application.routes.default_url_options[:host] = site.domain
    Rails.application.routes.default_url_options[:only_path] = false
  end

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
    assert_nil order.read_attribute(:total_price)

    order.confirm!

    assert order.read_attribute(:line_items_price)
    assert order.read_attribute(:total_price)
  end

  test "wait_for_offline_payment" do
    setup_emails
    order = create(:boutique_order, :confirmed)

    # user invite
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      perform_enqueued_jobs do
        order.wait_for_offline_payment!
      end
    end
  end

  test "pay" do
    setup_emails
    order = create(:boutique_order, :confirmed, email: "foo@test.test")

    assert_nil order.user
    assert order.primary_address.present?

    # user invite + order confirmation
    assert_difference("ActionMailer::Base.deliveries.size", 2) do
      perform_enqueued_jobs do
        order.pay!
      end
    end

    assert_equal "foo@test.test", order.user.email
    assert order.user.primary_address.present?

    order = create(:boutique_order, :confirmed, :with_user)

    # order confirmation
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      perform_enqueued_jobs do
        order.pay!
      end
    end
  end

  test "assign voucher by code" do
    order = create(:boutique_order, line_items_count: 1)
    order.line_items.first.product_variant.update_column(:regular_price, 100)

    assert_equal 100, order.total_price

    order.assign_voucher_by_code("TEST")

    assert order.errors[:voucher_code]
    assert_nil order.voucher
    assert_equal 100, order.total_price

    voucher = create(:boutique_voucher, code: "TEST", discount: 50, published: false)
    order.errors.clear
    order.assign_voucher_by_code("TEST")

    assert order.errors[:voucher_code]
    assert_nil order.voucher
    assert_equal 100, order.total_price

    voucher.update_column(:published, true)
    order.errors.clear
    order.assign_voucher_by_code("TEST")

    assert_empty order.errors[:voucher_code]
    assert_equal voucher, order.voucher
    assert_equal 50, order.total_price
  end

  test "confirm with voucher discount" do
    order = create(:boutique_order, :ready_to_be_confirmed)
    voucher = create(:boutique_voucher, code: "TEST", number_of_allowed_uses: 1)
    order.assign_voucher_by_code("TEST")

    assert_equal 0, voucher.use_count
    assert order.confirm!
    assert_equal 1, voucher.reload.use_count

    order = create(:boutique_order)
    order.assign_voucher_by_code("TEST")

    assert_not order.confirm!
    assert_equal 1, voucher.reload.use_count
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

  test "invoice numbers" do
    Boutique::Order.connection.execute("ALTER SEQUENCE boutique_orders_invoice_base_number_seq RESTART;")

    travel_to Time.zone.local(2022, 1, 1)
    order = create(:boutique_order, :confirmed)
    assert_nil order.invoice_number

    order.pay!
    assert_equal "2200001", order.invoice_number

    order = create(:boutique_order, :paid)
    assert_equal "2200002", order.invoice_number

    Boutique::Order.stub_any_instance(:invoice_number_prefix, "99") do
      order = create(:boutique_order, :paid)
      assert_equal "992200003", order.invoice_number
    end

    travel_to Time.zone.local(2023, 1, 1)
    order = create(:boutique_order, :paid)
    assert_equal "2300001", order.invoice_number
  end

  test "digital_only order shouldn't validate address" do
    order = create(:boutique_order, :ready_to_be_confirmed)

    assert order.primary_address.present?
    assert order.valid?

    order = create(:boutique_order, :ready_to_be_confirmed, digital_only: true)

    assert_not order.primary_address.present?
    assert order.valid?
  end

  test "event callbacks" do
    order = create(:boutique_order, :ready_to_be_confirmed)

    order.class_eval do
      attr_accessor :last_event

      def after_confirm
        @last_event = :confirm
      end

      def after_pay
        @last_event = :pay
      end
    end

    assert_nil order.last_event
    order.confirm!
    assert_equal order.last_event, :confirm
    order.pay!
    assert_equal order.last_event, :pay
  end
end
