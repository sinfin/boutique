# frozen_string_literal: true

class CreateBoutiqueProductVariants < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_product_variants do |t|
      t.references :boutique_product, null: false, foreign_key: true

      t.string :title

      t.integer :price, null: false

      t.boolean :master, default: false, index: { where: "master" }

      t.boolean :digital, default: false

      t.timestamps
    end

    add_belongs_to :boutique_line_items, :boutique_product_variant, null: false, foreign_key: true
  end
end
