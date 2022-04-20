# frozen_string_literal: true

class CreateBoutiqueOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_orders do |t|
      t.belongs_to :folio_user, foreign_key: true

      t.string :web_session_id

      t.integer :base_number
      t.string  :number
      t.string  :email
      t.string  :aasm_state, default: "pending"
      t.integer :line_items_count, default: 0
      t.integer :line_items_price
      t.integer :shipping_method_price
      t.integer :payment_method_price
      t.integer :total_price

      t.belongs_to :primary_address, index: false
      t.belongs_to :secondary_address, index: false
      t.boolean    :use_secondary_address, default: false

      t.datetime :confirmed_at
      t.datetime :paid_at
      t.datetime :dispatched_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :boutique_orders, :web_session_id
    add_index :boutique_orders, :number

    create_sequence :boutique_orders_base_number_seq
  end
end
