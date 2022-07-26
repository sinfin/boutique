# frozen_string_literal: true

class AddInvoiceNumberToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :invoice_number, :string

    create_sequence :boutique_orders_invoice_base_number_seq

    unless reverting?
      Boutique::Order.order(number: :asc).where.not(paid_at: nil).each do |order|
        order.send(:set_invoice_number)
        order.update_column(:invoice_number, order.invoice_number)
      end
    end
  end
end
