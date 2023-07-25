# frozen_string_literal: true

class AddEmailNotificationsToBoutiqueSubscriptions < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:boutique_subscriptions, :email_notifications)
      add_column :boutique_subscriptions, :email_notifications, :boolean, default: true
      add_index :boutique_subscriptions, :email_notifications
    end
  end
end
