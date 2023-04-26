# frozen_string_literal: true

require "boutique/go_pay/universal_gateway"
require "comgate_ruby"

Boutique.configure do |config|
  config.payment_gateways = {
    default: :go_pay,
    go_pay: Boutique::GoPay::UniversalGateway.new(test_calls: !Rails.env.production?,
                                                merchant_gateway_id: ENV.fetch("GO_PAY_GOID"), # merchant_id
                                                client_id: ENV.fetch("GO_PAY_CLIENT_ID"),  # client authorization id (username)
                                                client_secret: ENV.fetch("GO_PAY_CLIENT_SECRET")), # client authorization secret (password)
    comgate: Comgate::Gateway.new(merchant_gateway_id: ENV["COMGATE_MERCHANT_ID"],
                                  test_calls: !Rails.env.production?,
                                  client_secret: ENV["COMGATE_SECRET"])
  }
end
