# frozen_string_literal: true

class AddSubscriptionPeriodToVouchers < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_vouchers, :subscription_period, :integer, default: 1
  end
end
