# frozen_string_literal: true

if Rails.env.development?
  Boutique.configure do |config|
    config.using_cart = false
  end
end
