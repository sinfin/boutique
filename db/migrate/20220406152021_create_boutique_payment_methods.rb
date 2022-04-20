# frozen_string_literal: true

class CreateBoutiquePaymentMethods < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_payment_methods do |t|
      t.string :title
      t.string :type
      t.text :description

      t.string :price

      t.integer :position
      t.boolean :published, default: false

      t.timestamps
    end

    add_index :boutique_payment_methods, :position
    add_index :boutique_payment_methods, :published

    add_belongs_to :boutique_orders, :boutique_payment_method, foreign_key: true
  end
end
