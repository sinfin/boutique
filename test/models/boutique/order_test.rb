# frozen_string_literal: true

require "test_helper"

class Boutique::OrderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "add_line_item" do
    product_basic = create(:boutique_product)
    order = create(:boutique_order)

    assert_equal 0, order.line_items.count

    line_item = order.add_line_item!(product_basic.master_variant)

    assert_equal 1, order.line_items.count
    assert_equal 1, line_item.amount

    line_item = order.add_line_item!(product_basic.master_variant, amount: 2)

    assert_equal 1, order.line_items.count
    assert_equal 3, line_item.amount

    product_subscription = create(:boutique_product_subscription)
    line_item = order.add_line_item!(product_subscription.master_variant)

    assert_equal 2, order.line_items.count
    assert_equal 1, line_item.amount

    line_item = order.add_line_item!(product_subscription.master_variant)

    assert_equal 2, order.line_items.count
    assert_equal 1, line_item.amount

    line_item = order.add_line_item!(create(:boutique_product_subscription).master_variant)

    assert_equal 2, order.line_items.count
    assert_equal 1, line_item.amount
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
      assert order.send("#{state}_at")

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

  test "confirm on first_of_subsequent order will not trigger payment" do
    order = create(:boutique_order, :ready_to_be_confirmed, subscription_product: true)

    assert_not order.subsequent?

    def order.charge_recurrent_payment!
      raise "This should not be called!"
    end

    order.confirm!
  end

  test "confirm on subsequent order will trigger payment" do
    order = create(:boutique_order, :ready_to_be_confirmed, subscription_product: true)

    order.stubs(:subsequent?).returns(true)
    order.expects(:charge_recurrent_payment!).returns(true)

    order.confirm!
  end

  test "exception during charge_recurrent_payment! is not raised, just reported" do
    # so order can be saved to correct state
    order = create(:boutique_order, :ready_to_be_confirmed, subscription_product: true)

    failing_gateway = Boutique::PaymentGateway.new
    def failing_gateway.repeat_recurring_transaction(order)
      raise "Some error during payment"
    end

    order.stubs(:subsequent?).returns(true)
    order.stubs(:payment_gateway).returns(failing_gateway)
    order.expects(:report_exception) # .with(StandardError, order)

    order.confirm!

    assert order.reload.confirmed?
  end

  test "wait_for_offline_payment" do
    order = create(:boutique_order, :confirmed)

    # user invite
    assert_enqueued_jobs(1, only: ActionMailer::MailDeliveryJob) do
      order.wait_for_offline_payment!
    end
  end

  test "pay without user" do
    order = create(:boutique_order, :confirmed, email: "foo@test.test")

    assert_nil order.user
    assert order.primary_address.present?

    # user invite + order confirmation
    assert_enqueued_jobs(2, only: ActionMailer::MailDeliveryJob) do
      order.pay!
    end

    assert_equal "foo@test.test", order.user.email
    assert order.user.primary_address.present?
  end

  test "pay with user" do
    order = create(:boutique_order, :confirmed, :with_user)

    # order confirmation
    assert_enqueued_jobs(1, only: ActionMailer::MailDeliveryJob) do
      order.pay!
    end
  end

  test "pay (subscription) without previous subscription - auto prolonging" do
    # creates new subscription
    order = create(:boutique_order, :confirmed, subscription_product: true)
    payment = create(:boutique_payment, order:)
    sub_li = order.line_items.first
    assert sub_li.subscription?
    assert sub_li.subscription_recurring?

    assert_not order.subsequent?
    assert order.subscription.blank?
    assert order.first_of_subsequent?

    assert_difference("Boutique::Subscription.count", 1) do
      order.pay!
    end

    new_subscription = order.subscription.reload
    assert new_subscription.present?
    assert_equal sub_li.product_variant, new_subscription.product_variant
    assert_equal order.user, new_subscription.payer
    assert_equal order.user, new_subscription.user
    assert new_subscription.recurrent?
    assert_equal order.confirmed_at, new_subscription.active_from
    assert_equal order.confirmed_at + new_subscription.period.months, new_subscription.active_until
    assert_equal payment, new_subscription.payment
  end

  test "pay (subscription) without previous subscription - no auto prolonging" do
    # create new subscription
    order = create(:boutique_order, :confirmed, subscription_product: true)
    payment = create(:boutique_payment, order:)
    sub_li = order.line_items.first
    sub_li.update(subscription_recurring: false)
    assert sub_li.subscription?
    assert_not sub_li.subscription_recurring?

    assert_not order.subsequent?
    assert order.subscription.blank?
    assert_not order.first_of_subsequent?

    assert_difference("Boutique::Subscription.count", 1) do
      order.pay!
    end

    new_subscription = order.subscription.reload
    assert new_subscription.present?
    assert_equal sub_li.product_variant, new_subscription.product_variant
    assert_equal order.user, new_subscription.payer
    assert_equal order.user, new_subscription.user
    assert_not new_subscription.recurrent?
    assert_equal order.confirmed_at, new_subscription.active_from
    assert_equal order.confirmed_at + new_subscription.period.months, new_subscription.active_until
    assert_equal payment, new_subscription.payment
  end

  test "pay (subscription) with previous subscription - auto prolonging for subsequent order" do
    sub_active_until = 1.day.from_now
    subscription = create(:boutique_subscription, recurrent: true, period: 1, active_until: sub_active_until)

    order = create_confirmed_order_from_subscription(subscription)

    sub_li = order.line_items.first
    assert sub_li.subscription?
    assert sub_li.subscription_recurring?

    assert order.subsequent?
    assert order.subscription.present?
    assert_not order.first_of_subsequent?
    assert_equal sub_active_until.to_date, subscription.reload.active_until.to_date

    assert_no_difference("Boutique::Subscription.count") do
      order.pay!
    end

    assert_equal (sub_active_until + subscription.period.months).to_date, subscription.reload.active_until.to_date
  end

  test "pay (subscription) with previous active subscription - new user order for fixed period" do
    skip "should extend current subscription?"
  end

  test "pay (subscription) with previous active subscription - new user order with auto prolonging" do
    sub_active_until = 1.day.from_now
    subscription = create(:boutique_subscription, recurrent: true, period: 1, active_until: sub_active_until)

    order = create_confirmed_order_from_subscription(subscription)

    sub_li = order.line_items.first
    assert sub_li.subscription?
    assert sub_li.subscription_recurring?

    assert order.subsequent?
    assert order.subscription.present?
    assert_not order.first_of_subsequent?
    assert_equal sub_active_until.to_date, subscription.reload.active_until.to_date

    assert_no_difference("Boutique::Subscription.count") do
      order.pay!
    end

    assert_equal (sub_active_until + subscription.period.months).to_date, subscription.reload.active_until.to_date
  end

  test "pay (subscription) with previous active subscription (different tier) - new user order for fixed period" do
    skip "should create second subscription or upgrade existing, and from what time?"
  end

  test "dispatch" do
    order = create(:boutique_order, :paid)

    assert_enqueued_jobs(1, only: ActionMailer::MailDeliveryJob) do
      order.dispatch!
    end

    order = create(:boutique_order, :paid, digital_only: true)

    assert_enqueued_jobs(0, only: ActionMailer::MailDeliveryJob) do
      order.dispatch!
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

    travel_to Time.zone.local(2022, 2, 1)
    order = create(:boutique_order, :confirmed)
    assert_nil order.invoice_number

    order.pay!

    assert_equal "2200001", order.invoice_number

    order = create(:boutique_order, :paid, paid_at: Time.zone.local(2022, 2, 1))
    assert_equal "2200002", order.invoice_number

    Boutique::Order.stub_any_instance(:invoice_number_prefix, "99") do
      order = create(:boutique_order, :paid, paid_at: Time.zone.local(2022, 2, 1))
      assert_equal "229900003", order.invoice_number
    end

    Boutique.config.stub(:invoice_number_with_year_prefix, false) do
      order = create(:boutique_order, :paid, paid_at: Time.zone.local(2022, 2, 1))
      assert_equal "00004", order.invoice_number
    end

    order = create(:boutique_order, :paid, paid_at: Time.zone.local(2023, 1, 1))
    assert_equal "2300001", order.invoice_number

    Boutique.config.stub(:invoice_number_resets_each_year, false) do
      order = create(:boutique_order, :paid, paid_at: Time.zone.local(2024, 1, 1))
      assert_equal "2400002", order.invoice_number
    end
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

  test "scope by_number_query" do
    order = create(:boutique_order, number: "123456789")
    assert Boutique::Order.by_number_query("1234").exists?(id: order.id)
    assert Boutique::Order.by_number_query("5678").exists?(id: order.id)
    assert_not Boutique::Order.by_number_query("5607").exists?(id: order.id)
  end

  test "scope by_address_identification_number_query" do
    primary_address = create(:folio_address_primary, identification_number: "123456789")
    order = create(:boutique_order, primary_address:)

    assert Boutique::Order.by_address_identification_number_query("1234").exists?(id: order.id)
    assert Boutique::Order.by_address_identification_number_query("5678").exists?(id: order.id)
    assert_not Boutique::Order.by_address_identification_number_query("5607").exists?(id: order.id)
  end

  test "scope by_confirmed_at_range" do
    order = create(:boutique_order, confirmed_at: "1.1.2022 8:00")

    assert Boutique::Order.by_confirmed_at_range("1.1.2022").exists?(id: order.id)
    assert Boutique::Order.by_confirmed_at_range("1.1.2022-").exists?(id: order.id)
    assert Boutique::Order.by_confirmed_at_range("1.1.2022-1.1.2022").exists?(id: order.id)
    assert Boutique::Order.by_confirmed_at_range("1.1.2021-31.12.2023").exists?(id: order.id)
    assert_not Boutique::Order.by_confirmed_at_range("1.1.2021-31.12.2021").exists?(id: order.id)

    assert Boutique::Order.by_confirmed_at_range("1.1.2022 - ").exists?(id: order.id)
    assert Boutique::Order.by_confirmed_at_range(" - 1.1.2022").exists?(id: order.id)
    assert Boutique::Order.by_confirmed_at_range("1.1.2022 - 1.1.2022").exists?(id: order.id)
    assert Boutique::Order.by_confirmed_at_range("1.1.2021 - 31.12.2023").exists?(id: order.id)
    assert_not Boutique::Order.by_confirmed_at_range("1.1.2021 - 31.12.2021").exists?(id: order.id)
  end

  test "scope by_paid_at_range" do
    order = create(:boutique_order, paid_at: "1.1.2022 8:00")

    assert Boutique::Order.by_paid_at_range("1.1.2022").exists?(id: order.id)
    assert Boutique::Order.by_paid_at_range("1.1.2022-").exists?(id: order.id)
    assert Boutique::Order.by_paid_at_range("1.1.2022-1.1.2022").exists?(id: order.id)
    assert Boutique::Order.by_paid_at_range("1.1.2021-31.12.2023").exists?(id: order.id)
    assert_not Boutique::Order.by_paid_at_range("1.1.2021-31.12.2021").exists?(id: order.id)

    assert Boutique::Order.by_paid_at_range("1.1.2022 - ").exists?(id: order.id)
    assert Boutique::Order.by_paid_at_range(" - 1.1.2022").exists?(id: order.id)
    assert Boutique::Order.by_paid_at_range("1.1.2022 - 1.1.2022").exists?(id: order.id)
    assert Boutique::Order.by_paid_at_range("1.1.2021 - 31.12.2023").exists?(id: order.id)
    assert_not Boutique::Order.by_paid_at_range("1.1.2021 - 31.12.2021").exists?(id: order.id)
  end

  test "scope by_subscription_state" do
    active_subscription = create(:boutique_subscription,
                                 active_from: 1.month.ago,
                                 active_until: 1.month.from_now)

    inactive_subscription = create(:boutique_subscription,
                                   active_from: 1.month.ago,
                                   active_until: 2.weeks.ago)

    order = create(:boutique_order)

    assert_not Boutique::Order.by_subscription_state("active").exists?(id: order.id)
    assert_not Boutique::Order.by_subscription_state("inactive").exists?(id: order.id)
    assert Boutique::Order.by_subscription_state("none").exists?(id: order.id)

    order.update!(subscription: active_subscription)

    assert Boutique::Order.by_subscription_state("active").exists?(id: order.id)
    assert_not Boutique::Order.by_subscription_state("inactive").exists?(id: order.id)
    assert_not Boutique::Order.by_subscription_state("none").exists?(id: order.id)

    order.update!(subscription: inactive_subscription)

    assert_not Boutique::Order.by_subscription_state("active").exists?(id: order.id)
    assert Boutique::Order.by_subscription_state("inactive").exists?(id: order.id)
    assert_not Boutique::Order.by_subscription_state("none").exists?(id: order.id)
  end

  test "scope by_subsequent_subscription" do
    original_payment = create(:boutique_payment)

    active_subscription = create(:boutique_subscription,
                                 active_from: 1.month.ago,
                                 active_until: 1.month.from_now)

    order = create(:boutique_order)

    assert_not Boutique::Order.by_subsequent_subscription("new").exists?(id: order.id)
    assert_not Boutique::Order.by_subsequent_subscription("subsequent").exists?(id: order.id)

    order.update!(subscription: active_subscription)

    assert Boutique::Order.by_subsequent_subscription("new").exists?(id: order.id)
    assert_not Boutique::Order.by_subsequent_subscription("subsequent").exists?(id: order.id)

    order.update!(original_payment:)

    assert_not Boutique::Order.by_subsequent_subscription("new").exists?(id: order.id)
    assert Boutique::Order.by_subsequent_subscription("subsequent").exists?(id: order.id)
  end

  test "scope by_product_id" do
    line_item = create(:boutique_line_item)
    order = create(:boutique_order, line_items: [line_item])
    product = line_item.product

    other_product = create(:boutique_product)

    assert Boutique::Order.by_product_id(product.id).exists?(id: order.id)
    assert_not Boutique::Order.by_product_id(other_product.id).exists?(id: order.id)
  end

  test "scope by_number_range_from" do
    order = create(:boutique_order, number: "123456789")
    assert Boutique::Order.by_number_range_from("1").exists?(id: order.id)
    assert Boutique::Order.by_number_range_from("123456789").exists?(id: order.id)
    assert_not Boutique::Order.by_number_range_from("223456789").exists?(id: order.id)
  end

  test "scope by_number_range_to" do
    order = create(:boutique_order, number: "123456789")
    assert_not Boutique::Order.by_number_range_to("1").exists?(id: order.id)
    assert Boutique::Order.by_number_range_to("123456789").exists?(id: order.id)
    assert Boutique::Order.by_number_range_to("223456789").exists?(id: order.id)
  end

  test "scope by_total_price_range_from" do
    order = create(:boutique_order, total_price: 199)

    assert Boutique::Order.by_total_price_range_from(0).exists?(id: order.id)
    assert Boutique::Order.by_total_price_range_from(1).exists?(id: order.id)
    assert Boutique::Order.by_total_price_range_from(199).exists?(id: order.id)
    assert_not Boutique::Order.by_total_price_range_from(200).exists?(id: order.id)
  end

  test "scope by_total_price_range_to" do
    order = create(:boutique_order, total_price: 199)

    assert_not Boutique::Order.by_total_price_range_to(0).exists?(id: order.id)
    assert_not Boutique::Order.by_total_price_range_to(1).exists?(id: order.id)
    assert Boutique::Order.by_total_price_range_to(199).exists?(id: order.id)
    assert Boutique::Order.by_total_price_range_to(200).exists?(id: order.id)
  end

  test "scope by_voucher_title" do
    voucher = create(:boutique_voucher, title: "voucher title")
    order = create(:boutique_order, total_price: 199)

    assert_not Boutique::Order.by_voucher_title("voucher").exists?(id: order.id)
    assert_not Boutique::Order.by_voucher_title("vouc tit").exists?(id: order.id)
    assert_not Boutique::Order.by_voucher_title("tit").exists?(id: order.id)
    assert_not Boutique::Order.by_voucher_title("xaxa").exists?(id: order.id)

    order.update!(voucher:)

    assert Boutique::Order.by_voucher_title("voucher").exists?(id: order.id)
    assert Boutique::Order.by_voucher_title("vouc tit").exists?(id: order.id)
    assert Boutique::Order.by_voucher_title("tit").exists?(id: order.id)
    assert_not Boutique::Order.by_voucher_title("xaxa").exists?(id: order.id)
  end

  test "scope by_primary_address_country_code" do
    cz_address = create(:folio_address_primary, country_code: "CZ")
    sk_address = create(:folio_address_primary, country_code: "SK")
    order = create(:boutique_order)

    assert_not Boutique::Order.by_primary_address_country_code("CZ").exists?(id: order.id)
    assert_not Boutique::Order.by_primary_address_country_code("SK").exists?(id: order.id)
    assert Boutique::Order.by_primary_address_country_code("other").exists?(id: order.id)

    order.update!(primary_address: cz_address)

    assert Boutique::Order.by_primary_address_country_code("CZ").exists?(id: order.id)
    assert_not Boutique::Order.by_primary_address_country_code("SK").exists?(id: order.id)
    assert_not Boutique::Order.by_primary_address_country_code("other").exists?(id: order.id)

    order.update!(primary_address: sk_address)

    assert_not Boutique::Order.by_primary_address_country_code("CZ").exists?(id: order.id)
    assert Boutique::Order.by_primary_address_country_code("SK").exists?(id: order.id)
    assert_not Boutique::Order.by_primary_address_country_code("other").exists?(id: order.id)
  end

  test "scope by_non_pending_order_count_range_from" do
    user_a = create(:folio_user)
    user_b = create(:folio_user)

    order_a = create(:boutique_order, :confirmed, user: user_a)
    order_b_1 = create(:boutique_order, :confirmed, user: user_b)
    order_b_2 = create(:boutique_order, :confirmed, user: user_b)
    order_b_3 = create(:boutique_order, :confirmed, user: user_b)

    assert Boutique::Order.by_non_pending_order_count_range_from(0).exists?(id: order_a.id)
    assert Boutique::Order.by_non_pending_order_count_range_from(0).exists?(id: order_b_1.id)
    assert Boutique::Order.by_non_pending_order_count_range_from(0).exists?(id: order_b_2.id)
    assert Boutique::Order.by_non_pending_order_count_range_from(0).exists?(id: order_b_3.id)

    assert Boutique::Order.by_non_pending_order_count_range_from(1).exists?(id: order_a.id)
    assert Boutique::Order.by_non_pending_order_count_range_from(1).exists?(id: order_b_1.id)
    assert Boutique::Order.by_non_pending_order_count_range_from(1).exists?(id: order_b_2.id)
    assert Boutique::Order.by_non_pending_order_count_range_from(1).exists?(id: order_b_3.id)

    assert_not Boutique::Order.by_non_pending_order_count_range_from(3).exists?(id: order_a.id)
    assert Boutique::Order.by_non_pending_order_count_range_from(3).exists?(id: order_b_1.id)
    assert Boutique::Order.by_non_pending_order_count_range_from(3).exists?(id: order_b_2.id)
    assert Boutique::Order.by_non_pending_order_count_range_from(3).exists?(id: order_b_3.id)

    assert_not Boutique::Order.by_non_pending_order_count_range_from(4).exists?(id: order_a.id)
    assert_not Boutique::Order.by_non_pending_order_count_range_from(4).exists?(id: order_b_1.id)
    assert_not Boutique::Order.by_non_pending_order_count_range_from(4).exists?(id: order_b_2.id)
    assert_not Boutique::Order.by_non_pending_order_count_range_from(4).exists?(id: order_b_3.id)
  end

  test "scope by_non_pending_order_count_range_to" do
    user_a = create(:folio_user)
    user_b = create(:folio_user)

    order_a = create(:boutique_order, :confirmed, user: user_a)
    order_b_1 = create(:boutique_order, :confirmed, user: user_b)
    order_b_2 = create(:boutique_order, :confirmed, user: user_b)
    order_b_3 = create(:boutique_order, :confirmed, user: user_b)

    assert_not Boutique::Order.by_non_pending_order_count_range_to(0).exists?(id: order_a.id)
    assert_not Boutique::Order.by_non_pending_order_count_range_to(0).exists?(id: order_b_1.id)
    assert_not Boutique::Order.by_non_pending_order_count_range_to(0).exists?(id: order_b_2.id)
    assert_not Boutique::Order.by_non_pending_order_count_range_to(0).exists?(id: order_b_3.id)

    assert Boutique::Order.by_non_pending_order_count_range_to(1).exists?(id: order_a.id)
    assert_not Boutique::Order.by_non_pending_order_count_range_to(1).exists?(id: order_b_1.id)
    assert_not Boutique::Order.by_non_pending_order_count_range_to(1).exists?(id: order_b_2.id)
    assert_not Boutique::Order.by_non_pending_order_count_range_to(1).exists?(id: order_b_3.id)

    assert Boutique::Order.by_non_pending_order_count_range_to(3).exists?(id: order_a.id)
    assert Boutique::Order.by_non_pending_order_count_range_to(3).exists?(id: order_b_1.id)
    assert Boutique::Order.by_non_pending_order_count_range_to(3).exists?(id: order_b_2.id)
    assert Boutique::Order.by_non_pending_order_count_range_to(3).exists?(id: order_b_3.id)

    assert Boutique::Order.by_non_pending_order_count_range_to(4).exists?(id: order_a.id)
    assert Boutique::Order.by_non_pending_order_count_range_to(4).exists?(id: order_b_1.id)
    assert Boutique::Order.by_non_pending_order_count_range_to(4).exists?(id: order_b_2.id)
    assert Boutique::Order.by_non_pending_order_count_range_to(4).exists?(id: order_b_3.id)
  end

  test "scope by_query - name" do
    order = create(:boutique_order, first_name: "foo", last_name: "bar")

    assert Boutique::Order.by_query("foo bar").exists?(id: order.id)
    assert Boutique::Order.by_query("foo").exists?(id: order.id)
    assert Boutique::Order.by_query("bar").exists?(id: order.id)
    assert Boutique::Order.by_query("fo").exists?(id: order.id)
    assert Boutique::Order.by_query("ba").exists?(id: order.id)
    assert_not Boutique::Order.by_query("xaxa").exists?(id: order.id)
  end

  test "scope by_query - addresses" do
    primary_address = create(:folio_address_primary,
                             name: "Lorem Ipsum",
                             address_line_1: "Downing Street 10",
                             city: "London",
                             zip: "12345")
    order = create(:boutique_order, primary_address:)

    assert Boutique::Order.by_query("Downing Street 10").exists?(id: order.id)
    assert Boutique::Order.by_query("Downing").exists?(id: order.id)
    assert Boutique::Order.by_query("10").exists?(id: order.id)
    assert Boutique::Order.by_query("London").exists?(id: order.id)
    assert Boutique::Order.by_query("Lorem").exists?(id: order.id)
    assert Boutique::Order.by_query("Ips").exists?(id: order.id)
    assert Boutique::Order.by_query("12345").exists?(id: order.id)
    assert_not Boutique::Order.by_query("xaxa").exists?(id: order.id)
  end

  test "scope by_query - email" do
    order = create(:boutique_order, email: "foo@bar.baz")

    assert Boutique::Order.by_query("foo").exists?(id: order.id)
    assert Boutique::Order.by_query("fo").exists?(id: order.id)
    assert Boutique::Order.by_query("foo@bar.baz").exists?(id: order.id)
    assert_not Boutique::Order.by_query("xaxa").exists?(id: order.id)
  end

  test "validate gift_recipient_notification_scheduled_for" do
    I18n.with_locale(:en) do
      order = build(:boutique_order)
      assert order.valid?

      order.gift_recipient_notification_scheduled_for = 1.day.ago
      assert order.valid?

      order.force_gift_recipient_notification_scheduled_for_validation = true
      assert_not order.valid?
      assert_equal ["cannot be in the past"], order.errors[:gift_recipient_notification_scheduled_for]

      order.gift_recipient_notification_scheduled_for = 1.minute.from_now
      assert order.valid?
    end
  end

  # from SubscriptionBot + confirm
  def create_confirmed_order_from_subscription(subscription)
    original_order = subscription.original_order
    new_order = subscription.orders.build(original_order.attributes.slice(*%w[folio_user_id
                                                                            first_name
                                                                            last_name
                                                                            email
                                                                            use_secondary_address
                                                                            ]))
    # TODO: update product prices if needed
    new_order.line_items = original_order.line_items.map(&:dup)
    new_order.primary_address = original_order.primary_address.dup
    new_order.secondary_address = original_order.secondary_address.dup
    new_order.original_payment = subscription.payment

    def new_order.charge_recurrent_payment!
      payments.create!(remote_id: "transaction_id",
        amount: total_price,
        payment_method: "PAYMENT_CARD",
        payment_gateway_provider: :comgate)
    end
    new_order.confirm!
    new_order
  end
end
