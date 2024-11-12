# frozen_string_literal: true

class AddDeliveredAtToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :delivered_at, :datetime

    reversible do |dir|
      dir.up do
        Boutique::Order.where(aasm_state: "dispatched").update_all(aasm_state: "delivered")
      end

      dir.down do
        Boutique::Order.where(aasm_state: "delivered").update_all(aasm_state: "dispatched")
      end
    end
  end
end
