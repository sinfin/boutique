# frozen_string_literal: true

class AddAddressReferenceToSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_reference :boutique_subscriptions, :primary_address
  end
end
