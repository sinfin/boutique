# frozen_string_literal: true

class AddTransferFeeColumnToBoutiquePayments < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_payments, :transfer_fee, :decimal, default: 0.0, null: false
  end
end
