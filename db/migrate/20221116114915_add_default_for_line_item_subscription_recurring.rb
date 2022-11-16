# frozen_string_literal: true

class AddDefaultForLineItemSubscriptionRecurring < ActiveRecord::Migration[7.0]
  def change
    change_column_default :boutique_line_items, :subscription_recurring, from: nil, to: true
  end
end
