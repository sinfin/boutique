# frozen_string_literal: true

class AddInvoiceNumberToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :invoice_number, :string

    create_sequence :boutique_orders_invoice_base_number_seq
  end
end
