# frozen_string_literal: true

class InitBoutiqueShippingMethods < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_shipping_methods do |t|
      t.string :title
      t.integer :price_cz
      t.integer :price_sk

      t.string :type

      t.boolean :published, default: false
      t.integer :position

      t.timestamps
    end

    add_index :boutique_shipping_methods, :published
    add_index :boutique_shipping_methods, :position

    add_reference :boutique_orders, :shipping_method, foreign_key: { to_table: :boutique_shipping_methods, primary_key: :id }

    add_column :boutique_orders, :pickup_point_remote_id, :string
    add_column :boutique_orders, :pickup_point_title, :string
  end
end
