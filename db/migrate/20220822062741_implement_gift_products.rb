# frozen_string_literal: true

class ImplementGiftProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_orders, :gift, :boolean, default: false
    add_column :boutique_orders, :gift_recipient_email, :string
    add_column :boutique_orders, :gift_recipient_notification_date, :date
    add_column :boutique_orders, :gift_recipient_notification_sent_at, :datetime

    add_column :boutique_product_variants, :gift, :boolean, default: false
  end
end
