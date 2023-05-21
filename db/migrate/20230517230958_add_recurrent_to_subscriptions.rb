# frozen_string_literal: true

class AddRecurrentToSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_subscriptions, :recurrent, :boolean, default: false
    add_index :boutique_subscriptions, :recurrent

    unless reverting?
      Boutique::Subscription.where(cancelled_at: nil).update_all(recurrent: true)
    end
  end
end
