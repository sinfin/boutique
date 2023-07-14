# frozen_string_literal: true

class AddPackageDetailsToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :package_remote_id, :string
    add_column :boutique_orders, :package_tracking_id, :string
  end
end
