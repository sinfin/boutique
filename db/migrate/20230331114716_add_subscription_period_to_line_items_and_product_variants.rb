# frozen_string_literal: true

class AddSubscriptionPeriodToLineItemsAndProductVariants < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_line_items, :subscription_period, :integer
    add_column :boutique_product_variants, :subscription_period, :integer, default: 12

    Boutique::LineItem.update_all(subscription_period: 12) unless reverting?
  end
end
