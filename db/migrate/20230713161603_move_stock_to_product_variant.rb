# frozen_string_literal: true

class MoveStockToProductVariant < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_product_variants, :stock, :integer
    remove_column :boutique_products, :stock, :integer
  end
end
