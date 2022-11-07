# frozen_string_literal: true

class AddGtmDataSentAtToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :gtm_data_sent_at, :datetime, default: nil
  end
end
