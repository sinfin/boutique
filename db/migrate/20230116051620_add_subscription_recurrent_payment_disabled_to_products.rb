# frozen_string_literal: true

class AddSubscriptionRecurrentPaymentDisabledToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_products, :subscription_recurrent_payment_disabled, :boolean, default: false
  end
end
