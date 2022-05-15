# frozen_string_literal: true

class AddStiToBoutiqueProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_products, :type, :string
    add_index :boutique_products, :type
  end
end
