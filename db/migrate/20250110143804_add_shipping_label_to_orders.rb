# frozen_string_literal: true

class AddShippingLabelToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :shipping_label, :string
  end
end
