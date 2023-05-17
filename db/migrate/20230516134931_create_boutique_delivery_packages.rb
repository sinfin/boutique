# frozen_string_literal: true

class CreateBoutiqueDeliveryPackages < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_delivery_packages do |t|
      t.string :number
      t.belongs_to :shipment, null: false, foreign_key: { to_table: :boutique_delivery_shipments, primary_key: :id }
      t.string :aasm_state
      t.jsonb :state_history

      t.timestamps
    end

    create_table :boutique_delivery_line_item_package_links do |t|
      t.belongs_to :line_item, null: false, foreign_key: { to_table: :boutique_line_items, primary_key: :id }
      t.belongs_to :package, null: false, foreign_key: { to_table: :boutique_delivery_packages, primary_key: :id }
      t.timestamps
    end
  end
end
