# frozen_string_literal: true

class CreateBoutiqueOrderRefunds < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_order_refunds do |t|
      t.string :document_number
      t.string :secret_hash
      t.references :boutique_order, null: false, foreign_key: true
      t.string :aasm_state

      t.date :issue_date
      t.date :due_date
      t.date :date_of_taxable_supply

      t.text :reason
      t.date :subscription_refund_from
      t.date :subscription_refund_to
      t.integer :subscriptions_price_in_cents, default: 0
      t.integer :total_price_in_cents, default: 0
      t.string :payment_method

      t.datetime :paid_at
      t.datetime :approved_at
      t.datetime :cancelled_at

      t.timestamps
    end
  end
end
