# frozen_string_literal: true

class AddPreviewTokenToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_products, :preview_token, :string
  end
end
