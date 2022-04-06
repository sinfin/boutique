# frozen_string_literal: true

class CreateWipifyProductVariants < ActiveRecord::Migration[7.0]
  def change
    create_table :wipify_product_variants do |t|
      t.references :wipify_product, null: false, foreign_key: true

      t.string :title

      t.integer :price, null: false

      t.boolean :master, default: false, index: { where: "master = true" }

      t.timestamps
    end

    add_belongs_to :wipify_line_items, :wipify_product_variant, null: false, foreign_key: true
  end
end
