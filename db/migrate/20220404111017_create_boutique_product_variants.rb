# frozen_string_literal: true

class CreateBoutiqueProductVariants < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_product_variants do |t|
      t.references :boutique_product, null: false, foreign_key: true

      t.string :title

      t.integer :regular_price, null: false

      t.integer :discounted_price
      t.datetime :discounted_from
      t.datetime :discounted_until

      t.boolean :master, default: false

      t.boolean :digital_only, default: false

      t.timestamps
    end

    add_index :boutique_product_variants, :master, where: "master"

    add_belongs_to :boutique_line_items, :boutique_product_variant, null: false, foreign_key: true
  end
end
