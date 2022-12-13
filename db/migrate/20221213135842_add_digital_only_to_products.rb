# frozen_string_literal: true

class AddDigitalOnlyToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_products, :digital_only, :boolean, default: false
    remove_column :boutique_product_variants, :digital_only, :boolean, default: false
  end
end
