# frozen_string_literal: true

class CreateBoutiqueLineItems < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_line_items do |t|
      t.belongs_to :boutique_order, null: false, foreign_key: true

      t.integer :amount, default: 1
      t.integer :unit_price

      t.datetime :subscription_starts_at
      t.boolean :subscription_recurring

      t.timestamps
    end
  end
end
