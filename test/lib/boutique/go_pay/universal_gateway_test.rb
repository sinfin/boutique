# frozen_string_literal: true

require "test_helper"

class GoPay::UniversalGatewayTest < ActiveSupport::TestCase
  test "select right endpoints" do
    GoPay::Gateway.expects(:new)
                  .with(gate: "https://testgw.gopay.cz",
                    goid: gateway_params[:merchant_gateway_id],
                    client_id: gateway_params[:client_id],
                    client_secret: gateway_params[:client_secret])

    Boutique::GoPay::UniversalGateway.new(**gateway_params.merge({ test_calls: true }))

    GoPay::Gateway.expects(:new)
                  .with(gate: "https://gate.gopay.cz",
                    goid: gateway_params[:merchant_gateway_id],
                    client_id: gateway_params[:client_id],
                    client_secret: gateway_params[:client_secret])

    Boutique::GoPay::UniversalGateway.new(**gateway_params.merge({ test_calls: false }))
  end

  test "handles callbacks" do
    transaction_id = 3186828749
    request_params = { "order_id" => "joQNtFWDudZAxk9gOmFEUA", "id" => transaction_id }

    GoPay::Gateway.any_instance
                  .expects(:retrieve)
                  .with(transaction_id)
                  .returns(gopay_response_for(transaction_id:, state: "CREATED"))

    gateway = Boutique::GoPay::UniversalGateway.new(**gateway_params)
    result = gateway.process_callback(request_params)

    assert_not result.redirect?
    assert_nil result.redirect_to
    # state CREATED is translated for us to :pending
    assert_equal expected_result_hash_for(transaction_id:, state: :pending), result.hash
  end

  test "make right call to check transaction" do
    transaction_id = "asdsadasd"

    GoPay::Gateway.any_instance
                  .expects(:retrieve)
                  .with(transaction_id)
                  .returns(gopay_response_for(transaction_id:, state: "CREATED"))

    gateway = Boutique::GoPay::UniversalGateway.new(**gateway_params)
    result = gateway.check_transaction(transaction_id:)

    assert_not result.redirect?
    assert_nil result.redirect_to
    # state CREATED is translated for us to :pending
    assert_equal expected_result_hash_for(transaction_id:, state: :pending), result.hash
  end

  test "make right call for creating payment" do
    transaction_id = "asdsadasd"

    payment_data = simple_payment_data

    gopay_response = gopay_response_for(transaction_id:, state: "PAID")
    gopay_response["gw_url"] =  "https://gw.sandbox.gopay.com/gw/v3/bCcvmwTKK5hrJx2aGG8ZnFyBJhAvF"

    expected_result_hash = expected_result_hash_for(transaction_id:, state: :paid)
    expected_result_hash[:redirect_to] = gopay_response["gw_url"]

    GoPay::Gateway.any_instance
                  .expects(:create)
                  .with(expected_gopay_payload_for(payment_data))
                  .returns(gopay_response)

    gateway = Boutique::GoPay::UniversalGateway.new(**gateway_params)
    result = gateway.start_transaction(payment_data)

    assert result.redirect?
    assert_equal gopay_response["gw_url"], result.redirect_to
    assert_equal expected_result_hash, result.hash
  end

  test "make right call for creating recurring payment" do
    transaction_id = "asdsadasd"

    payment_data = simple_payment_data
    payment_data[:payment][:recurrence] = {
      cycle: :month,
      period: 1,
      valid_to: Date.new(2025, 12, 31),
    }
    expected_gopay_payload = expected_gopay_payload_for(payment_data)
    expected_gopay_payload["recurrence"] = {
      "recurrence_cycle": "MONTH",  # not passed for ON_DEMAND
      "recurrence_period": 1,
      "recurrence_date_to": "2025-12-31",
    }

    gopay_response = gopay_response_for(transaction_id:, state: "PAID")
    gopay_response["gw_url"] =  "https://gw.sandbox.gopay.com/gw/v3/bCcvmwTKK5hrJx2aGG8ZnFyBJhAvF"
    gopay_response["recurrence"] = {
      "recurrence_cycle" => "MONTH",
      "recurrence_period" => 1,
      "recurrence_date_to" => "2025-12-31",
      "recurrence_state" => "REQUESTED"
    }
    expected_result_hash = expected_result_hash_for(transaction_id:, state: :paid)
    expected_result_hash[:redirect_to] = gopay_response["gw_url"]
    expected_result_hash[:payment][:recurrence] = {
      cycle: :month,
      period: 1,
      valid_to: Date.new(2025, 12, 31),
      state: :requested
    }

    GoPay::Gateway.any_instance
                  .expects(:create)
                  .with(expected_gopay_payload)
                  .returns(gopay_response)

    gateway = Boutique::GoPay::UniversalGateway.new(**gateway_params)
    result = gateway.start_recurring_transaction(payment_data)

    assert result.redirect?
    assert_equal gopay_response["gw_url"], result.redirect_to
    assert_equal expected_result_hash, result.hash
  end

  test "make right call for refund of payment" do
    transaction_id = "asdsadasd"
    amount_in_cents = 555
    payment_data = {
      transaction_id:,
      payment: {
        amount_in_cents:,
        currency: "CZK",
        reference_id: "aasasas"
      }
    }

    new_transaction_id = 465789654
    gopay_response = {
      "id" => new_transaction_id,
      "result" => "FINISHED"
    }
    expected_result_hash = {
      code: 0,
      message: "OK",
      transaction_id: new_transaction_id,
      state: :finished,
      redirect_to: nil
    }

    GoPay::Gateway.any_instance
                  .expects(:refund)
                  .with(transaction_id, amount_in_cents)
                  .returns(gopay_response)

    gateway = Boutique::GoPay::UniversalGateway.new(**gateway_params)
    result = gateway.refund_transaction(payment_data)

    assert_not result.redirect?
    assert_equal expected_result_hash, result.hash
  end

  private
    def gateway_params
      { test_calls: true,
        merchant_gateway_id: 'ENV.fetch("GO_PAY_GOID")', # merchant_id
        client_id: 'ENV.fetch("GO_PAY_CLIENT_ID")',  # client authorization id (username)
        client_secret: 'ENV.fetch("GO_PAY_CLIENT_SECRET")' } # client authorization secret (password)
    end

    def simple_payment_data
      {
        payer: { email: "john@example.com",
                 phone: "+420777888999",
                 first_name: "John",
                 last_name: "Doe",
                 street_line: "21 Narrow street",
                 city: "Springfield",
                 postal_code: "12345",
                 country_code3: "USA" },
        merchant: { target_shop_account: "12345678/1234" },
        payment: { currency: "CZK",
                   amount_in_cents: 100, # 1 CZK
                   label: "#2023-0123",
                   reference_id: "#2023-0123",
                   description: "Some description of order",
                   method: "PAYMENT_CARD",
                   product_name: "Usefull things" },
        options: {
          country_code: "DE", # show payment methods for Germany
          language_code: "sk",
           shop_return_url: "https://eshop.cz/order/asdaARFEG56",
           callback_url: "https://eshop.cz/callbacks/gopay",
        },
        items: [
          {
            type: "ITEM",
            name: "Je to kulatý – Měsíční (6. 6. 2023 – 6. 7. 2023)",
            price_in_cents: 9900,
            count: 1,
            vat_rate_percent: 21
          }
        ],
        test: true
      }
    end

    def expected_gopay_payload_for(payment_data)
      {
        payer: {
          default_payment_instrument: payment_data[:payment][:method],
          contact:  {
            first_name: payment_data[:payer][:first_name],
            last_name: payment_data[:payer][:last_name],
            phone_number: payment_data[:payer][:phone],
            email: payment_data[:payer][:email],
            city: payment_data[:payer][:city],
            street: payment_data[:payer][:street_line],
            postal_code: payment_data[:payer][:postal_code],
            country_code: payment_data[:payer][:country_code3]
          }
        },
        # target: {
        #   type: "ACCOUNT",
        #   goid: gateway_params[:merchant_gateway_id]
        # },
        items: gopay_items_array(payment_data[:items]),
        amount: payment_data[:payment][:amount_in_cents],
        currency: payment_data[:payment][:currency],
        order_number: payment_data[:payment][:reference_id],
        order_description: payment_data[:payment][:description],
        lang: payment_data[:options][:language_code],

        # callback are not required ?!
        callback: {
          return_url: payment_data[:options][:shop_return_url],
          notification_url: payment_data[:options][:callback_url]
        },
      }
    end

    def gopay_response_for(transaction_id:, state: "PAID")
      {
        "id" => transaction_id,
        "order_number" => "OBJ20200825",
        "state" => state,
        "amount" => 139950,
        "currency" => "CZK",
        "payment_instrument" => "PAYMENT_CARD",
        "payer" => {
            "allowed_payment_instruments" => [
                "PAYMENT_CARD",
                "BANK_ACCOUNT"
            ],
            "default_payment_instrument" => "PAYMENT_CARD",
            "allowed_swifts" => [
                "FIOBCZPP",
                "BREXCZPP"
            ],
            "default_swift" => "FIOBCZPP",
            "contact" => {
                "first_name" => "Zbyněk",
                "last_name" => "Žák",
                "email" => "test@test.cz",
                "phone_number" => "+420777456123",
                "city" => "České Budějovice",
                "street" => "Planá 67",
                "postal_code" => "37301",
                "country_code" => "CZE"
            },
            "payment_card" => {
                "card_number" => "444444******4448",
                "card_expiration" => "1909",
                "card_brand" => "VISA",
                "card_issuer_country" => "CZE",
                "card_issuer_bank" => "AIR BANK, A.S.",
                "3ds_result" => "Y/Y"
            }
        },
        "target" => {
            "type" => "ACCOUNT",
            "goid" => 8123456789
        },
        "additional_params" => [
            {
                "name" => "invoicenumber",
                "value" => "2015001003"
            }
        ],
        "lang" => "CS",
        "gw_url" => " https://gw.sandbox.gopay.com/gw/v3/bCcvmwTKK5hrJx2aGG8ZnFyBJhAvF"
      }
    end

    # corresponds to `gopay_response_for(transaction_id: , state: "PAID")`
    def expected_result_hash_for(transaction_id:, state: :paid)
      {
        code: 0,
        message: "OK",
        transaction_id:,
        state:,
        # recurrence: {
        #   cycle: resp.dig("recurrence", "recurrence_cycle"),
        #   period: resp.dig("recurrence", "recurrence_period"),
        #   valid_to: resp.dig("recurrence", "recurrence_date_to"),
        #   state:  convert_state(resp.dig("recurrence", "recurrence_state"))
        # },
        # preauthorization: {
        #   requested: resp.dig("preauthorization", "requested"),
        #   state:  convert_state(resp.dig("preauthorization", "state"))
        # },
        # redirect_to: nil,
        payment: {
          amount_in_cents: 139950,
          currency: "CZK",
          label: "",
          reference_id: "OBJ20200825",
          method: "PAYMENT_CARD",
          product_name: "",
          fee: nil,
          variable_symbol: nil,
          description: nil
        },
        payer: {
          email: "test@test.cz",
          phone: "+420777456123",
          first_name: "Zbyněk",
          last_name: "Žák",
          street_line: "Planá 67",
          city: "České Budějovice",
          postal_code: "37301",
          country_code2: nil,
          country_code3: "CZE",
          account_number: nil,
          account_name: nil
        }
      }
    end


    def gopay_items_array(payment_data_items)
      return nil if payment_data_items.blank?

      payment_data_items.collect do |item_hash|
        { type: item_hash[:type],
          name: item_hash[:name],
          amount: item_hash[:price_in_cents],
          count: item_hash[:count],
          vat_rate: item_hash[:vat_rate_percent] }
      end
    end
end
