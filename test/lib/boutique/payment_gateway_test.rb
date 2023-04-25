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
    transaction_id ="ABS-123"
    pgw_response =  Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: transaction_id,
      redirect_to: nil,
      hash: { code: 0, state: :paid },
      array: nil
    )
    gw = Boutique::PaymentGateway.new
    gw.provider_gateway
      .expects(:check_transaction)
      .with(transaction_id: transaction_id)
      .returns(pgw_response)

    resp = gw.check_transaction(transaction_id)

    assert_not resp.redirect?
    assert_equal :paid, resp.hash[:state]
  end

  test "#start_transaction(order, options)" do
    order = create(:boutique_order, :confirmed)
    transaction_id = "1345679ABCD"
    options = {
      payment_method: "PAYMENT_CARD",
      return_url: "https://www.boutique.com",
      callback_url: "https://www.boutique.com/callbacks"
    }

    pgw_response =  Boutique::PaymentGateway::ResponseStruct.new(
      transaction_id: transaction_id,
      redirect_to: "https://www.boutique.com",
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
    assert_equal pgw_response, resp
  end

  test "prepares data for start_recurring_transaction(order)" do
    skip
  end

  test "prepares data for repeat_recurring_transaction(payment_data)" do
    skip
  end

  test "prepares data for process_callback(payload)" do
    skip
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

  test "prepares data for refund_transaction(payment_data)" do
    skip
  end

  test "prepares data for cancel_transaction(transaction_id)" do
    skip
  end

  test "prepares data for allowed_payment_methods(params)" do
    skip
  end

  test "handles gateway errors" do
    skip
  end

  private

    def payment_data_for(order, options)
      params = {
        payer: { email: order.email,
                phone: nil,
                first_name: order.first_name,
                last_name: order.last_name },
        payment: { currency: order.currency_code,
                  amount_in_cents: order.total_price * 100,
                  label: order.to_label,
                  reference_id: order.number,
                  description: "#{order.model_name.human} #{order.to_label}",
                  method: options[:payment_method],
                  product_name: order.model_name.human },
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

      if order.line_items.any? { |li| li.subscription? && li.subscription_recurring? }
        params[:recurrence] = {
          cycle: "ON_DEMAND",
          valid_to: "2099-12-31"
        }
      end
      params
    end

    def items_hash(order)
      order.line_items.map do |line_item|
        {
          type: "ITEM",
          name: line_item.to_label,
          amount: line_item.price * 100,
          count: line_item.amount,
          vat_rate: line_item.vat_rate_value.to_i,
        }
      end
    end
end
