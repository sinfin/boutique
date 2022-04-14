# frozen_string_literal: true

class CreateWipifyLineItems < ActiveRecord::Migration[7.0]
  def change
    create_table :wipify_line_items do |t|
      t.belongs_to :wipify_order, null: false, foreign_key: true

      t.integer :amount, default: 1
      t.integer :unit_price

      t.timestamps
    end
  end
end
