# frozen_string_literal: true

class UpdateGiftOrderImplementation < ActiveRecord::Migration[7.0]
  def up
    remove_column :boutique_product_variants, :gift

    change_column :boutique_orders, :gift_recipient_notification_date, :datetime
    rename_column :boutique_orders, :gift_recipient_notification_date, :gift_recipient_notification_scheduled_for
  end

  def down
    add_column :boutique_product_variants, :gift, :boolean, default: false

    rename_column :boutique_orders, :gift_recipient_notification_scheduled_for, :gift_recipient_notification_date
    change_column :boutique_orders, :gift_recipient_notification_date, :date
  end
end
