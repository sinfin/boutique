# frozen_string_literal: true

class CreateBoutiqueSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_subscriptions do |t|
      t.belongs_to :boutique_order, foreign_key: true
      t.belongs_to :boutique_payment, foreign_key: true
      t.belongs_to :boutique_product_variant, null: false, foreign_key: true
      t.belongs_to :folio_user, null: false, foreign_key: true

      t.integer :period, default: 12

      t.datetime :active_from
      t.datetime :active_until
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :boutique_subscriptions, :active_from
    add_index :boutique_subscriptions, :active_until
    add_index :boutique_subscriptions, :cancelled_at
  end
end
