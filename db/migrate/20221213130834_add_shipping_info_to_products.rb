# frozen_string_literal: true

class AddShippingInfoToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_products, :shipping_info, :text
  end
end
