# frozen_string_literal: true

class UpdateSubscriptionRecurringLineItemsDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :boutique_line_items, :subscription_recurring, from: true, to: nil
  end
end
