class CreateBoutiqueOrderRefunds < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_order_refunds do |t|
      t.string :number
      t.date :issue_date
      t.date :due_date
      t.date :date_of_taxable_supply
      t.references :boutique_order, null: false, foreign_key: true
      t.text :reason
      t.integer :total_price_in_cents
      t.string :aasm_state
      t.datetime :paid_at
      t.datetime :cancelled_at

      t.timestamps
    end
  end
end
