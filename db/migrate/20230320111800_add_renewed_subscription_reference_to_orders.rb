# frozen_string_literal: true

class AddRenewedSubscriptionReferenceToOrders < ActiveRecord::Migration[7.0]
  def change
    add_reference :boutique_orders, :renewed_subscription
  end
end
