# frozen_string_literal: true

class CreateWipifyShippingMethods < ActiveRecord::Migration[7.0]
  def change
    create_table :wipify_shipping_methods do |t|
      t.string :title
      t.string :type
      t.text :description

      t.string :price

      t.integer :position
      t.boolean :published, default: false

      t.timestamps
    end

    add_index :wipify_shipping_methods, :position
    add_index :wipify_shipping_methods, :published

    add_belongs_to :wipify_orders, :wipify_shipping_method, foreign_key: true
  end
end
