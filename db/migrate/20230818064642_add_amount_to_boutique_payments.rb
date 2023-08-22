# frozen_string_literal: true

class AddAmountToBoutiquePayments < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_payments, :amount, :decimal, precision: 10, scale: 2, null: true
  end
end
