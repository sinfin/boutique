# frozen_string_literal: true

class AddReferralUrlToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :referrer_url, :string
  end
end
