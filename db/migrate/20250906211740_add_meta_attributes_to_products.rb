# frozen_string_literal: true

class AddMetaAttributesToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_products, :meta_title, :string, limit: 512
    add_column :boutique_products, :meta_description, :text
    add_column :boutique_products, :og_title, :string
  end
end
