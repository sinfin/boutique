# frozen_string_literal: true

class AddSiteReferenceToProductsAndOrders < ActiveRecord::Migration[7.0]
  def change
    add_reference :boutique_products, :site
    add_reference :boutique_orders, :site
  end
end
