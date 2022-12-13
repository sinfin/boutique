# frozen_string_literal: true

Boutique.configure do |config|
  config.use_cart_in_orders = false if Rails.env.development?
end
