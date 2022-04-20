# frozen_string_literal: true

class CreateBoutiqueProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_products do |t|
      t.string :title, null: false
      t.string :slug, null: false

      t.boolean :published, default: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :boutique_products, :slug
    add_index :boutique_products, :published
    add_index :boutique_products, :published_at
  end
end
