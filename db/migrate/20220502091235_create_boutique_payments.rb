# frozen_string_literal: true

class CreateBoutiquePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_payments do |t|
      t.belongs_to :boutique_order, null: false, foreign_key: true

      t.bigint :remote_id
      t.string :aasm_state, default: "pending"
      t.string :payment_method

      t.datetime :paid_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :boutique_payments, :remote_id
  end
end
