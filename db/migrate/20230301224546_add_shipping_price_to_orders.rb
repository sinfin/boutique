# frozen_string_literal: true

class AddShippingPriceToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :shipping_price, :integer

    unless reverting?
      Boutique::Order.where.not(total_price: nil).update_all(shipping_price: 0)
    end
  end
end
