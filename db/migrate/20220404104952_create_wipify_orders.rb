# frozen_string_literal: true

class CreateWipifyOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :wipify_orders do |t|
      t.belongs_to :customer, polymorphic: true

      t.integer :base_number
      t.string  :number, index: true
      t.string  :email
      t.integer :line_items_count, default: 0
      t.integer :line_items_price
      t.integer :total_price

      t.timestamps
    end
  end
end
