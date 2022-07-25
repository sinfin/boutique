# frozen_string_literal: true

class AddBillingDetailsToSites < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_sites, :billing_name, :string
    add_column :folio_sites, :billing_address_line_1, :string
    add_column :folio_sites, :billing_address_line_2, :string
    add_column :folio_sites, :billing_identification_number, :string
    add_column :folio_sites, :billing_vat_identification_number, :string
    add_column :folio_sites, :billing_note, :string
  end
end
