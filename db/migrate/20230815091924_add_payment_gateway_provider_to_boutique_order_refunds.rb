# frozen_string_literal: true

class AddPaymentGatewayProviderToBoutiqueOrderRefunds < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_order_refunds, :payment_gateway_provider, :string
  end
end
