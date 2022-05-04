# frozen_string_literal: true

Boutique.configure do |config|
  config.using_cart = false if Rails.env.development?

  config.data_protection_page_type = "Dummy::Page::DataProtection"
  config.terms_page_type = "Dummy::Page::Terms"
end
