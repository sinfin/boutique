# frozen_string_literal: true

require "test_helper"

class Boutique::GoPay::ApiTest < ActiveSupport::TestCase
  test "payment payload for a regular order" do
    payload = create_payment_payload(intro_price: nil)

    assert_equal 14900, payload[:amount]
    assert_not payload.key?(:preauthorization)
    assert_equal "ON_DEMAND", payload[:recurrence][:recurrence_cycle]
  end

  test "payment payload for a free introductory subscription" do
    payload = create_payment_payload(intro_price: 0)

    # the gateway refuses a zero amount without preauthorization
    assert_equal 0, payload[:amount]
    assert_equal true, payload[:preauthorization]

    # the card has to stay usable for the first real payment
    assert_equal "ON_DEMAND", payload[:recurrence][:recurrence_cycle]
    assert_equal [0], payload[:items].map { |item| item[:amount] }
  end

  private
    # Runs create_payment against a stubbed gateway and returns the payload that
    # would have been sent to GoPay.
    def create_payment_payload(intro_price:)
      order = confirmed_intro_order(intro_price:)

      payload = nil
      gateway = mock
      gateway.expects(:create).with do |data|
        payload = data
        true
      end.returns({})

      api = Boutique::GoPay::Api.new
      api.stubs(:gateway).returns(gateway)
      api.create_payment(order, controller: url_helpers_stub)

      payload
    end

    def url_helpers_stub
      controller = mock
      controller.stubs(:comeback_go_pay_url).returns("https://test.test/comeback")
      controller.stubs(:notify_go_pay_url).returns("https://test.test/notify")
      controller
    end

    def confirmed_intro_order(intro_price:)
      product = create(:boutique_product_subscription,
                       regular_price: 149,
                       subscription_period: 1,
                       intro_enabled: intro_price.present?,
                       intro_price:,
                       intro_duration_months: intro_price.present? ? 2 : nil)

      order = create(:boutique_order, :ready_to_be_confirmed, :with_user, line_items_count: 0)
      order.line_items << build(:boutique_line_item, product:, order:)
      order.save!

      assert order.confirm!, "order not confirmed: #{order.errors.full_messages.to_sentence}"

      order
    end
end
