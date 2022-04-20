# frozen_string_literal: true

class CreateBoutiqueShippingMethods < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_shipping_methods do |t|
      t.string :title
      t.string :type
      t.text :description

      t.string :price

      t.integer :position
      t.boolean :published, default: false

      t.timestamps
    end

    add_index :boutique_shipping_methods, :position
    add_index :boutique_shipping_methods, :published

    add_belongs_to :boutique_orders, :boutique_shipping_method, foreign_key: true
  end
end
