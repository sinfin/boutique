# frozen_string_literal: true

class AddCheckoutTermsAgreementToSites < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_sites, :checkout_terms_agreement, :text
  end
end
