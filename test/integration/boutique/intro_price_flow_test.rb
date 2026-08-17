# frozen_string_literal: true

require "test_helper"

# The introductory price has to survive the whole journey: the checkout, the
# trip through the payment gateway, the subscription it sets up and the
# recurrences the bot charges afterwards. The individual steps have their own
# unit tests - this covers the seams between them.
class Boutique::IntroPriceFlowTest < Boutique::ControllerTest
  include Boutique::Test::GoPayApiMocker
  include Devise::Test::IntegrationHelpers

  test "a discounted introductory price is charged for every introductory period" do
    order = checkout(intro_product(intro_price: 49, intro_duration_months: 3))

    pay_at_gateway(order)

    assert_equal 49, order.total_price
    assert_not_nil order.invoice_number, "a discounted order is invoiced as usual"

    subscription = order.subscription.reload
    active_from = subscription.active_from

    # charged per period, so the first one is a regular period
    assert_equal (active_from + 1.month).to_i, subscription.active_until.to_i
    assert_equal (active_from + 3.months).to_i, subscription.intro_until.to_i

    assert_equal 49, charge_recurrence(subscription).total_price
    assert_equal (active_from + 2.months).to_i, subscription.reload.active_until.to_i

    assert_equal 49, charge_recurrence(subscription).total_price
    assert_equal (active_from + 3.months).to_i, subscription.reload.active_until.to_i

    # the introductory window is over now
    assert_equal 149, charge_recurrence(subscription).total_price
    assert_equal (active_from + 4.months).to_i, subscription.reload.active_until.to_i
  end

  test "a free trial is paid for in one block and renews for the full price" do
    order = checkout(intro_product(intro_price: 0, intro_duration_months: 2))

    # nothing is charged, but the card is authorized - the gateway answers
    # AUTHORIZED instead of PAID, see Boutique::Order#zero_amount_authorization?
    pay_at_gateway(order, state: "AUTHORIZED", amount: 0)

    assert_equal 0, order.total_price
    assert_nil order.invoice_number, "a 0 Kč order is not invoiced"

    subscription = order.subscription.reload
    active_from = subscription.active_from

    # the whole introductory block is paid for at once
    assert_equal (active_from + 2.months).to_i, subscription.active_until.to_i
    assert_equal subscription.active_until.to_i, subscription.intro_until.to_i

    # there is no second free period to charge zero for
    assert_equal 149, charge_recurrence(subscription).total_price
    assert_equal (active_from + 3.months).to_i, subscription.reload.active_until.to_i
  end

  test "a subscription cancelled during the introductory block is never charged" do
    order = checkout(intro_product(intro_price: 0, intro_duration_months: 2))
    pay_at_gateway(order, state: "AUTHORIZED", amount: 0)

    subscription = order.subscription.reload
    subscription.cancel!

    # the whole block has elapsed, so the bot would pick the subscription up
    subscription.update_column(:active_until, Time.current.beginning_of_hour + 6.hours + 30.minutes)

    assert_no_difference("Boutique::Order.count") do
      Boutique::SubscriptionBot.new.charge_all_eligible
    end

    # proof the bot would have charged it had it not been cancelled
    subscription.update_column(:cancelled_at, nil)
    go_pay_create_recurrent_payment_api_call_mock(id: next_remote_id)

    assert_difference("Boutique::Order.count", 1) do
      Boutique::SubscriptionBot.new.charge_all_eligible
    end
  end

  test "a voucher does not stack on top of the introductory price" do
    # half of the regular price is still more than the introductory one, so the
    # voucher adds nothing - the same way it behaves for a promotional price
    voucher = create(:boutique_voucher, discount: 50, discount_in_percentages: true)
    order = checkout(intro_product(intro_price: 49, intro_duration_months: 3),
                     voucher_code: voucher.code)

    pay_at_gateway(order)

    assert_equal 49, order.line_items_price
    assert_equal 0, order.discount
    assert_equal 49, order.total_price

    # the voucher was a one-off, the recurrence stays on the intro price
    assert_equal 49, charge_recurrence(order.subscription.reload).total_price
  end

  test "a voucher bigger than the introductory reduction still applies" do
    # 80 % off 149 is 119, the introductory price already saves 100 of it
    voucher = create(:boutique_voucher, discount: 80, discount_in_percentages: true)
    order = checkout(intro_product(intro_price: 49, intro_duration_months: 3),
                     voucher_code: voucher.code)

    pay_at_gateway(order)

    assert_equal 19, order.discount
    assert_equal 30, order.total_price
  end

  test "an order made free by a voucher never reaches the gateway" do
    voucher = create(:boutique_voucher, discount: 100, discount_in_percentages: true)

    # no create_payment mock on purpose - calling the gateway would blow up
    order = checkout(intro_product, voucher_code: voucher.code, expect_gateway: false)

    assert order.reload.is_paid?
    assert_equal 0, order.total_price
    assert_empty order.payments
  end

  test "a subscription without an introductory price is unaffected" do
    order = checkout(intro_product)

    pay_at_gateway(order)

    assert_equal 149, order.total_price

    subscription = order.subscription.reload
    assert_nil subscription.intro_until
    assert_nil subscription.original_line_item.subsequent_unit_price

    assert_equal 149, charge_recurrence(subscription).total_price
  end

  test "a signed in customer who already had a subscription is told on arrival" do
    product = intro_product(intro_price: 49, intro_duration_months: 3)
    user = create(:folio_user)
    past_subscription_for(user, product)

    sign_in user

    order = add_to_order(product)

    # the offer is gone the moment the checkout opens - the customer clicked an
    # introductory price and has to learn why they are not seeing it
    get edit_order_url
    assert_response :success
    assert_match "úvodní cena již není dostupná", flash[:warning].to_s
    assert_equal 149, order.reload.total_price

    # having been told, the confirm goes straight through for the full price
    go_pay_create_payment_api_call_mock
    post confirm_order_url, params: { order: confirm_params(order, email: user.email) }
    assert_redirected_to mocked_go_pay_payment_gateway_url

    assert_equal 149, order.reload.total_price
    assert_nil order.line_items.first.intro_duration_months
  end

  test "a guest is judged by the e-mail they fill in and can then buy for the full price" do
    # otherwise the checkout turns a registered e-mail down before it ever gets
    # to the introductory price
    Boutique.config.stubs(:allow_guest_checkout_with_registered_email).returns(true)

    product = intro_product(intro_price: 0, intro_duration_months: 2)
    user = create(:folio_user)
    past_subscription_for(user, product)

    order = add_to_order(product)
    assert_equal 0, order.total_price

    body = { order: confirm_params(order, email: user.email) }

    # no create_payment mock on purpose - a denied checkout must not get to the
    # gateway with a price the customer has not seen
    post confirm_order_url, params: body
    assert_redirected_to edit_order_url

    follow_redirect!
    assert_match "trial již není dostupný", flash[:warning].to_s

    # the e-mail is kept, so the checkout keeps recognizing the customer and
    # keeps showing the regular price even if they reload the page
    order.reload
    assert order.pending?
    assert_equal user.email, order.email
    assert_equal 149, order.total_price

    go_pay_create_payment_api_call_mock

    post confirm_order_url, params: body
    assert_redirected_to mocked_go_pay_payment_gateway_url

    order.reload
    assert order.confirmed?
    assert_equal 149, order.total_price
    assert_nil order.line_items.first.intro_duration_months
    assert_nil order.line_items.first.subsequent_unit_price
  end

  test "a trial bought as a gift runs for the recipient and renews on the payer's card" do
    product = intro_product(intro_price: 0, intro_duration_months: 2)

    order = checkout(product, gift_recipient_email: "recipient@test.test")

    pay_at_gateway(order, state: "AUTHORIZED", amount: 0)

    assert_equal 0, order.total_price

    subscription = order.subscription.reload
    active_from = subscription.active_from

    # the gift is announced first, the trial only starts then
    assert_equal order.gift_recipient_notification_scheduled_for.to_i, active_from.to_i
    assert_equal (active_from + 2.months).to_i, subscription.active_until.to_i

    # until the gift is delivered the subscription has a payer but no holder
    assert_nil subscription.user
    assert_equal order.user, subscription.payer

    order.deliver_gift!

    assert_equal "recipient@test.test", subscription.reload.user.email

    # the trial is over and the recurrence is charged to whoever paid for the
    # gift, the same as any other gift subscription
    assert_equal 149, charge_recurrence(subscription).total_price
    assert_equal order.user, subscription.reload.payer
    assert_equal (active_from + 3.months).to_i, subscription.active_until.to_i
  end

  # A gift stays without a holder between being paid for and being handed over,
  # so the recipient cannot be recognized through Folio::User#subscriptions the
  # way anybody else is - the queue of undelivered gifts has to be asked too,
  # see Boutique::Order.undelivered_gifts_for.
  test "a second trial cannot be gifted to the same address while the first is queued" do
    product = intro_product(intro_price: 0, intro_duration_months: 2)

    first = checkout(product, gift_recipient_email: "recipient@test.test")
    pay_at_gateway(first, state: "AUTHORIZED", amount: 0)

    assert_nil first.subscription.reload.user, "the gift has no holder yet"
    assert_nil first.reload.gift_recipient_notification_sent_at
    assert_nil Folio::User.find_by(email: "recipient@test.test"), "the recipient has no account either"

    body = { order: confirm_params(add_to_order(product), gift_recipient_email: "recipient@test.test") }

    # no create_payment mock on purpose - the customer must see the price first
    post confirm_order_url, params: body
    assert_redirected_to edit_order_url

    follow_redirect!
    assert_match "trial nabídnout nemůžeme", flash[:warning].to_s

    second = Boutique::Order.last.reload
    assert_equal 149, second.total_price
    assert_nil second.line_items.first.intro_duration_months

    # the first gift is still on its way, untouched
    assert_equal 0, first.reload.total_price
  end

  test "a gift is judged by its recipient, not by the customer paying for it" do
    product = intro_product(intro_price: 0, intro_duration_months: 2)
    recipient = create(:folio_user)
    past_subscription_for(recipient, product)

    order = add_to_order(product)
    assert_equal 0, order.total_price

    body = { order: confirm_params(order, gift_recipient_email: recipient.email) }

    # no create_payment mock on purpose - the customer must see the price first
    post confirm_order_url, params: body
    assert_redirected_to edit_order_url

    follow_redirect!
    assert_match "trial nabídnout nemůžeme", flash[:warning].to_s
    assert_equal 149, order.reload.total_price

    go_pay_create_payment_api_call_mock

    post confirm_order_url, params: body
    assert_redirected_to mocked_go_pay_payment_gateway_url

    order.reload
    assert order.confirmed?
    assert_equal 149, order.total_price
    assert_nil order.line_items.first.intro_duration_months
  end

  test "a customer who has used their own entitlement up can still gift a trial" do
    product = intro_product(intro_price: 0, intro_duration_months: 2)
    user = create(:folio_user)
    past_subscription_for(user, product)

    sign_in user

    order = checkout(product, email: user.email, gift_recipient_email: "recipient@test.test")

    assert_nil flash[:warning]
    assert_equal 0, order.reload.total_price
    assert_equal 2, order.line_items.first.intro_duration_months
  end

  test "a guest who has never subscribed keeps the introductory price" do
    product = intro_product(intro_price: 0, intro_duration_months: 2)
    create(:folio_user, email: "someone.else@test.test")

    order = checkout(product)

    assert_nil flash[:warning]
    assert_equal 0, order.reload.total_price
    assert_equal 2, order.line_items.first.intro_duration_months
  end

  private
    def intro_product(intro_price: nil, intro_duration_months: nil)
      create(:boutique_product_subscription,
             digital_only: true,
             regular_price: 149,
             subscription_period: 1,
             intro_enabled: intro_price.present?,
             intro_price:,
             intro_duration_months:)
    end

    # A subscription the customer already holds - the factory insists on building
    # its own user, so the owner has to be moved afterwards.
    def past_subscription_for(user, product)
      subscription = create(:boutique_subscription, product_variant: product.master_variant)
      subscription.update!(user:)
      subscription
    end

    # Walks the checkout the way a customer does and returns the pending order.
    def checkout(product, expect_gateway: true, **params)
      order = add_to_order(product)

      go_pay_create_payment_api_call_mock if expect_gateway

      post confirm_order_url, params: { order: confirm_params(order, **params) }

      if expect_gateway
        assert_redirected_to mocked_go_pay_payment_gateway_url
      end

      order
    end

    def add_to_order(product)
      post add_order_url(product)
      assert_redirected_to edit_order_url

      Boutique::Order.last
    end

    def confirm_params(order, voucher_code: nil, email: "intro@test.test", gift_recipient_email: nil)
      params = {
        first_name: "John",
        last_name: "Doe",
        email:,
        voucher_code:,
        primary_address_attributes: build(:boutique_folio_primary_address).serializable_hash,
        line_items_attributes: [{ id: order.line_items.first.id, subscription_recurring: true }],
      }

      if gift_recipient_email.present?
        params.merge!(gift: true,
                      gift_recipient_email:,
                      gift_recipient_first_name: "Jane",
                      gift_recipient_last_name: "Roe",
                      gift_recipient_notification_scheduled_for: 2.days.from_now.strftime("%d. %m. %Y %H:%M"))
      end

      params
    end

    def pay_at_gateway(order, state: "PAID", amount: 14900)
      go_pay_find_payment_api_call_mock(state:, amount:)

      get comeback_go_pay_url(id: 123, order_id: order.secret_hash)

      # a digital order is dispatched and delivered right away, so #paid? is
      # already false by the time we get here
      assert order.reload.is_paid?, "the order was not paid: #{order.aasm_state}"
    end

    # One turn of the bot: it builds and confirms the next order, the gateway
    # then reports the recurrent payment as paid. Returns the new order.
    def charge_recurrence(subscription)
      remote_id = next_remote_id

      go_pay_create_recurrent_payment_api_call_mock(id: remote_id)

      assert_difference("subscription.orders.reload.count", 1) do
        Boutique::SubscriptionBot.new.charge(Boutique::Subscription.where(id: subscription.id))
      end

      subsequent_order = subscription.current_order

      go_pay_find_payment_api_call_mock(id: remote_id)
      get notify_go_pay_url(id: remote_id, order_id: subsequent_order.secret_hash)
      assert_response :success

      assert subsequent_order.reload.is_paid?, "the recurrent payment was not accepted"

      subsequent_order
    end

    def next_remote_id
      @next_remote_id = (@next_remote_id || 123) + 1
    end
end
