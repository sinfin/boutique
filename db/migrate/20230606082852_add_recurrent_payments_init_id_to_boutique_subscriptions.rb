# frozen_string_literal: true

class AddRecurrentPaymentsInitIdToBoutiqueSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_subscriptions, :recurrent_payments_init_id, :string, after: :recurrent
  end
end
