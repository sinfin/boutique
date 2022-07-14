# frozen_string_literal: true

class AddSubscriptionFrequencyToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_products, :subscription_frequency, :string

    unless reverting?
      Boutique::Product::Subscription.update_all(subscription_frequency: Boutique::Product::SUBSCRIPTION_FREQUENCY_OPTIONS.first)
    end
  end
end
