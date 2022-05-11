# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = "noreply@dummy.com"
  config.mailer = "Dummy::DeviseMailer"
end
