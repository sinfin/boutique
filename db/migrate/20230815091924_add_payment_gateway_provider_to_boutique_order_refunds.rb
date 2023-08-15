class AddPaymentGatewayProviderToBoutiqueOrderRefunds < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_order_refunds, :payment_gateway_provider, :string

    Boutique::OrderRefund.find_each do |orf|
      orf.save!
    end
  end
end
