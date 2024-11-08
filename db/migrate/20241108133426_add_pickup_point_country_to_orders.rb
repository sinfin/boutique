# frozen_string_literal: true

class AddPickupPointCountryToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :pickup_point_country_code, :string, limit: 2
    rename_column :boutique_orders, :pickup_point_remote_id, :pickup_point_id
  end
end
