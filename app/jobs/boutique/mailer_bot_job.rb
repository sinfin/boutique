# frozen_string_literal: true

class Boutique::MailerBotJob < Boutique::ApplicationJob
  queue_as :default

  def perform
    Boutique::MailerBot.perform_all
  end
end
