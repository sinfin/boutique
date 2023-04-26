# frozen_string_literal: true

require "gopay"

GoPay::Error.class_eval do
  attr_accessor :code, :body

  def self.handle_gopay_error(response)
    e = new("#{response.code} : #{response.body}")
    e.code = response.code
    e.body = JSON.parse(response.body)
    e
  end
end

# #<GoPay::Error: 409 : {"date_issued":"2023-04-26T15:58:18.581+0200",
#                        "errors":[{"scope":"G","error_code":340,"error_name":"PAYMENT_RECURRENCE_FAILED","message":"Recurring payment failed"}]}>

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
