# frozen_string_literal: true

class ChangeRemoteIdTypeAtPayments < ActiveRecord::Migration[7.0]
  def up
    change_column :boutique_payments, :remote_id, :string
  end

  def down
    change_column :boutique_payments, :remote_id, :bigint
  end
end
