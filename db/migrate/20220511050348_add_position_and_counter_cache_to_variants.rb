# frozen_string_literal: true

class AddPositionAndCounterCacheToVariants < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_product_variants, :position, :integer
    add_index :boutique_product_variants, :position

    add_column :boutique_product_variants, :slug, :string
    add_index :boutique_product_variants, :slug

    add_column :boutique_products, :variants_count, :integer, default: 0

    rename_column :boutique_product_variants, :contents, :checkout_sidebar_content
    add_column :boutique_product_variants, :description, :text
  end
end
