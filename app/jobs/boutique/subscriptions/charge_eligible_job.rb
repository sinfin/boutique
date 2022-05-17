# frozen_string_literal: true

class Boutique::Subscriptions::ChargeEligibleJob < ApplicationJob
  queue_as :default

  def perform
    Boutique::SubscriptionBot.charge_all_eligible
  end
end
