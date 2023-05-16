# frozen_string_literal: true

class AddPaymentGatewayProviderToBoutiquePayments < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_payments, :payment_gateway_provider, :string
  end
end
