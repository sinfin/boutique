# frozen_string_literal: true

class AddExpirationDateToSubscriptionsAndPayments < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_subscriptions, :payment_expiration_date, :date

    add_column :boutique_payments, :card_number, :string, limit: 32
    add_column :boutique_payments, :card_valid_until, :string, limit: 5
  end
end
