# frozen_string_literal: true

class AddRecurringPaymentDisclaimerToSites < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_sites, :recurring_payment_disclaimer, :text
  end
end
