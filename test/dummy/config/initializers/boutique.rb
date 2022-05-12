# frozen_string_literal: true

Boutique.configure do |config|
  config.using_cart = false if Rails.env.development?

  config.orders_edit_sidebar_shipping_content = "<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>"
end
