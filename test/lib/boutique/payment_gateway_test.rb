# frozen_string_literal: true

require "test_helper"

class Boutique::PaymentGatewayTest < ActiveSupport::TestCase
  test "default provider is go_pay" do
    gw = Boutique::PaymentGateway.new

    assert_equal :go_pay, gw.provider
    assert gw.provider_gateway.is_a?(Boutique::GoPay::UniversalGateway)
  end

  test "select gateway according to param" do
    gw = Boutique::PaymentGateway.new(:go_pay)

    assert_equal :go_pay, gw.provider
    assert gw.provider_gateway.is_a?(Boutique::GoPay::UniversalGateway)
    assert_equal true, gw.provider_gateway.test_calls_used?

    gw = Boutique::PaymentGateway.new(:comgate)

    assert_equal :comgate, gw.provider
    assert gw.provider_gateway.is_a?(Comgate::Gateway)
    assert_equal true, gw.provider_gateway.test_calls_used?
  end

  test "#check_transaction(transaction_id)" do
    transaction_id = "ABS-123"
    pgw_response = Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id:,
      redirect_to: nil,
      hash: { code: 0, state: :paid },
      array: nil
    )
    gw = Boutique::PaymentGateway.new
    gw.provider_gateway
      .expects(:check_transaction)
      .with(transaction_id:)
      .returns(pgw_response)

    resp = gw.check_transaction(transaction_id)

    assert_not resp.redirect?
    assert_equal :paid, resp.hash[:state]
  end

  test "#start_transaction(order, options)" do
    order = create(:boutique_order, :confirmed)

    response_transaction_id = "1345679ABCD"
    options = {
      payment_method: "PAYMENT_CARD",
      return_url: "https://www.boutique.com",
      callback_url: "https://www.boutique.com/callbacks"
    }

    pgw_response = Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: response_transaction_id,
      redirect_to: "https://www.paymentgateway/pay?id=#{response_transaction_id}",
      hash: { code: 0, message: "OK" },
      array: nil
    )

    gw = Boutique::PaymentGateway.new
    gw.provider_gateway
      .expects(:start_transaction)
      .with(payment_data_for(order, options))
      .returns(pgw_response)

    resp = gw.start_transaction(order, options)

    assert resp.redirect?
    assert pgw_response.redirect_to, resp.redirect_to
    assert_equal pgw_response, resp
  end

  test "#start_recurring_transaction(order)" do
    order = create(:boutique_order, :confirmed)
    assert order.line_items.reload.none?(&:requires_subscription_recurring?)

    gw = Boutique::PaymentGateway.new

    assert_raises "cannot create recurrence for non-recurrent order" do
      gw.start_recurring_transaction(order)
    end

    order.line_items << create(:boutique_line_item, product: create(:boutique_product_subscription))
    assert order.line_items.reload.any?(&:requires_subscription_recurring?)

    options = {
      payment_method: "PAYMENT_CARD",
      return_url: "https://www.boutique.com",
      callback_url: "https://www.boutique.com/callbacks"
    }
    payment_data = payment_data_for(order, options)
    payment_data[:payment][:recurrence] = {
      cycle: :on_demand,
      period: 1,
      valid_to: Date.new(2099, 12, 31)
    }

    response_transaction_id = "1345679ABCD"
    pgw_response = Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: response_transaction_id,
      redirect_to: "https://www.paymentgateway/pay?id=#{response_transaction_id}",
      hash: { code: 0, message: "OK" },
      array: nil
    )

    gw.provider_gateway
      .expects(:start_recurring_transaction)
      .with(payment_data)
      .returns(pgw_response)

    resp = gw.start_recurring_transaction(order, options)

    assert resp.redirect?
    assert pgw_response.redirect_to, resp.redirect_to
    assert_equal pgw_response, resp
  end

  test "#repeat_recurring_transaction(order)" do
    subscription = create(:boutique_subscription)
    first_order = subscription.orders.first
    orig_payment = first_order.paid_payment
    init_transaction_id = orig_payment.remote_id
    assert init_transaction_id.present?

    gw = Boutique::PaymentGateway.new

    assert_raises "cannot create recurrence for non-recurrent order" do
      assert_nil first_order.original_payment
      gw.repeat_recurring_transaction(first_order)
    end

    # subsequent order is created in SubscriptionBot
    subsequent_order = create(:boutique_order, :ready_to_be_confirmed,
                                               subscription:,
                                               original_payment_id: orig_payment.id)

    payment_data = payment_data_for(subsequent_order, {})
    payment_data[:payment][:recurrence] = {
      init_transaction_id:,
      period: 2,
    }

    new_transaction_id = "96382ab"
    pgw_response = Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: new_transaction_id,
      redirect_to: nil,
      hash: { code: 0, message: "OK", recurrence: { init_transaction_id: } },
      array: nil
    )

    gw = Boutique::PaymentGateway.new
    gw.provider_gateway
      .expects(:repeat_recurring_transaction)
      .with(payment_data)
      .returns(pgw_response)

    resp = gw.repeat_recurring_transaction(subsequent_order)

    assert_not resp.redirect?
    assert_nil resp.redirect_to
    assert_equal pgw_response, resp
  end

  test "#process_callback(payload)" do
    transaction_id = "dadsad64686"
    comgate_like_params = { "transId" => transaction_id, "status" => "CANCELLED", "merchant" => "merch_id" }
    gopay_like_params = { "id" => transaction_id }

    comgate_response =  Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id:,
      redirect_to: nil,
      hash: { code: 0, message: "OK", state: :cancelled },
      array: nil
    )

    gopay_response = Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id:,
      redirect_to: nil,
      hash: { code: 0, message: "OK", state: :timeouted },
      array: nil
    )

    Comgate::Gateway.any_instance
                    .expects(:process_callback)
                    .with(comgate_like_params)
                    .returns(comgate_response)
    Comgate::Gateway.any_instance
                    .expects(:check_transaction)
                    .with(transaction_id:)
                    .returns(comgate_response)

    Boutique::GoPay::UniversalGateway.any_instance
                    .expects(:process_callback)
                    .with(gopay_like_params)
                    .returns(gopay_response)

    resp = Boutique::PaymentGateway.process_callback(comgate_like_params)

    assert_equal :cancelled, resp.hash[:state], resp.to_json

    resp = Boutique::PaymentGateway.process_callback(gopay_like_params)

    assert_equal :timeouted, resp.hash[:state], resp.to_json
  end

  test "prepares data for start_preauthorized_transaction(payment_data)" do
    skip
  end

  test "prepares data for confirm_preauthorized_transaction(payment_data)" do
    skip
  end

  test "prepares data for cancel_preauthorized_transaction(transaction_id)" do
    skip
  end

  test "prepares data for start_verification_transaction(payment_data)" do
    skip
  end

  test "#refund_transaction(payment, amount)" do
    refund_amount = 12345.0 # czk
    order = build(:boutique_order, total_price: refund_amount * 2, number: 42)
    b_payment = build(:boutique_payment, order:)
    payment_data = {
      transaction_id: b_payment.remote_id,
      payment: {
        amount_in_cents: refund_amount * 100,
        currency: "CZK",
        reference_id: order.number
      }
    }

    new_transaction_id = "96382ab"
    pgw_response = Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: new_transaction_id,
      redirect_to: nil,
      hash: { code: 0, message: "OK", transaction_id: new_transaction_id, state: :finished },
      array: nil
    )

    gw = Boutique::PaymentGateway.new
    gw.provider_gateway
      .expects(:refund_transaction)
      .with(payment_data)
      .returns(pgw_response)

    resp = gw.refund_transaction(b_payment, refund_amount)

    assert_not resp.redirect?
    assert_nil resp.redirect_to
    assert_equal pgw_response, resp
  end

  test "prepares data for cancel_transaction(transaction_id)" do
    skip
  end

  test "#allowed_payment_methods(params)" do
    skip
  end

  test "handles gateway errors" do
    skip
  end

  private
    def payment_data_for(order, options)
      params = {
        payer: {
          email: order.email,
          phone: nil,
          first_name: order.first_name,
          last_name: order.last_name
        },
        payment: {
          currency: order.currency_code,
          amount_in_cents: order.total_price * 100,
          label: order.to_label,
          reference_id: order.number,
          description: "#{order.model_name.human} #{order.to_label}",
          method: options[:payment_method],
          product_name: order.model_name.human
        },
        options: {
          country_code: options[:country_of_purchase_code] || "CZ",
          language_code: options[:language_code] || "cs",
          shop_return_url: options[:return_url],
          callback_url: options[:callback_url],
        },
        items: items_hash(order),
      }

      if address = order.secondary_address || order.primary_address
        params[:payer][:city] =	address.city
        params[:payer][:street_line] =	[address.address_line_1, address.address_line_2].compact.join(", ")
        params[:payer][:postal_code] =  address.zip
        params[:payer][:country_code2] = address.country_code if address.country_code.size == 2
        params[:payer][:country_code3] = address.country_code if address.country_code.size == 3
      end

      params
    end

    def items_hash(order)
      order.line_items.map do |line_item|
        {
          type: "ITEM",
          name: line_item.to_label,
          price_in_cents: line_item.price * 100,
          count: line_item.amount,
          vat_rate_percent: line_item.vat_rate_value.to_i,
        }
      end
    end
end
