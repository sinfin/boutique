# frozen_string_literal: true

class AddVoucherReferenceToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :discount, :integer
    add_column :boutique_orders, :voucher_code, :string

    add_reference :boutique_orders, :boutique_voucher, foreign_key: true
  end
end
