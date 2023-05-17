# frozen_string_literal: true

class CreateBoutiqueDeliveryShipments < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_delivery_shipments do |t|
      t.belongs_to :order, null: false, foreign_key: { to_table: :boutique_orders, primary_key: :id }
      t.string :aasm_state
      t.integer :branch_id
      t.jsonb :address
      t.string :shipper_tracking_number
      t.string :last_mile_carrier_tracking_number
      t.jsonb :tracking_history
      t.jsonb :state_history

      t.timestamps
    end
  end
end
