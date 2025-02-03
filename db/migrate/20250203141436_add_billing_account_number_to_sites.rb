# frozen_string_literal: true

class AddBillingAccountNumberToSites < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_sites, :billing_account_number, :string
  end
end
