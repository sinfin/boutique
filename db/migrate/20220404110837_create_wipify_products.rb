# frozen_string_literal: true

class CreateWipifyProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :wipify_products do |t|
      t.string :title, null: false
      t.string :slug, null: false

      t.boolean :published, default: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :wipify_products, :slug
    add_index :wipify_products, :published
    add_index :wipify_products, :published_at
  end
end
