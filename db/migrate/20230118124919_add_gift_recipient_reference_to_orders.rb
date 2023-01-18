# frozen_string_literal: true

class AddGiftRecipientReferenceToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :gift_recipient_first_name, :string
    add_column :boutique_orders, :gift_recipient_last_name, :string
    add_reference :boutique_orders, :gift_recipient
  end
end
