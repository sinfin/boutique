# frozen_string_literal: true

class AddConfirmedAtAtIndexToOrders < ActiveRecord::Migration[7.0]
  def change
    add_index :boutique_orders, :confirmed_at
  end
end
