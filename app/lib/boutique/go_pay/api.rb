# frozen_string_literal: true

GoPay::Error.class_eval do
  attr_accessor :code, :body

  def self.handle_gopay_error(response)
    e = new("#{response.code} : #{response.body}")
    e.code = response.code
    e.body = JSON.parse(response.body)
    e
  end
end

GoPay::Gateway.class_eval do
  def payment_instruments(currency = "CZK")
    @client.request(:get, "/api/eshops/eshop/#{@goid}/payment-instruments/#{currency}")
  end

  def create_recurrent_payment(id, payment_data)
    @client.request(:post,
                    "/api/payments/payment/#{id}/create-recurrence",
                    body_parameters: payment_data)
  end
end

class Boutique::GoPay::Api
  CURRENCY = "CZK"
  DEFAULT_PAYMENT_METHOD = "PAYMENT_CARD"

  attr_reader :controller

  def gateway
    @gateway ||= GoPay::Gateway.new(gate: ENV.fetch("GO_PAY_GATE"),
                                    goid: ENV.fetch("GO_PAY_GOID"),
                                    client_id: ENV.fetch("GO_PAY_CLIENT_ID"),
                                    client_secret: ENV.fetch("GO_PAY_CLIENT_SECRET"))
  end

  def find_payment(id)
    gateway.retrieve(id)
  end

  def create_payment(order, controller:, payment_method: nil)
    data = payment_hash(order, controller:, payment_method:)
    gateway.create(data)
  end

  def refund_payment(id, order)
    gateway.refund(id, order.total_price * 100)
  end

  def create_recurrent_payment(order)
    fail "cannot create recurrence for non-recurrent order" if order.original_payment.nil?

    data = {
      items: items_hash(order),
      amount: order.total_price * 100,
      currency: CURRENCY,
      order_number: order.number,
      order_description: order_description(order),
    }

    gateway.create_recurrent_payment(order.original_payment.remote_id, data)
  end

  private
    def payment_hash(order, controller:, payment_method: nil)
      contact = {
        first_name: order.first_name,
        last_name: order.last_name,
        email: order.email,
      }

      if address = order.primary_address.presence
        contact.merge!(
          city:	address.city,
          street:	[address.address_line_1, address.address_line_2].compact.join(", "),
          postal_code: address.zip,
          country_code:	address.country_code,
        )
      end

      result = {
        payer: {
          default_payment_instrument: payment_method.presence || DEFAULT_PAYMENT_METHOD,
          contact:
        },
        items: items_hash(order),
        amount: order.total_price * 100,
        currency: CURRENCY,
        order_number: order.number,
        order_description: order_description(order),
        callback: {
          return_url: controller.comeback_go_pay_url(order_id: order.secret_hash),
          notification_url: controller.notify_go_pay_url(order_id: order.secret_hash),
        },
        lang: :cs
      }

      if order.line_items.any? { |li| li.subscription? && li.subscription_recurring? }
        result[:recurrence] = {
          recurrence_cycle: "ON_DEMAND",
          # recurrence as long as possible
          recurrence_date_to: "2099-12-31"
        }
      end

      result
    end

    def items_hash(order)
      order.line_items.map do |line_item|
        {
          type: "ITEM",
          name: line_item.to_label,
          amount: line_item.price * 100,
          count: line_item.amount,
          vat_rate: line_item.vat_rate.to_i,
        }
      end
    end

    def order_description(order)
      "#{order.model_name.human} #{order.to_label}"
    end
end
