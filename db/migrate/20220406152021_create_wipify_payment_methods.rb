# frozen_string_literal: true

class CreateWipifyPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    create_table :wipify_payment_methods do |t|
      t.string :title
      t.string :type
      t.text :description

      t.string :price

      t.integer :position, index: true
      t.boolean :published, default: false, index: { where: "published = true" }

      t.timestamps
    end

    add_belongs_to :wipify_orders, :wipify_payment_method, foreign_key: true
  end
end
