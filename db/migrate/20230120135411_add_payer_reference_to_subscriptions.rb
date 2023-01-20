# frozen_string_literal: true

class AddPayerReferenceToSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_reference :boutique_subscriptions, :payer

    remove_foreign_key :boutique_subscriptions, :folio_users
    change_column_null :boutique_subscriptions, :folio_user_id, from: false, to: true

    unless reverting?
      say_with_time "updating subscriptions" do
        Boutique::Subscription.joins(:payment).includes(payment: :order).find_each do |subscription|
          subscription.update_columns(payer_id: subscription.payment.order.folio_user_id)
        end
      end
    end
  end
end
