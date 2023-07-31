# frozen_string_literal: true

class AddPickupPointDetailsToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :pickup_point_remote_id, :integer
    add_column :boutique_orders, :pickup_point_title, :string
  end
end
