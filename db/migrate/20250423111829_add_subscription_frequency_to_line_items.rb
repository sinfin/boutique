# frozen_string_literal: true

class AddSubscriptionFrequencyToLineItems < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_line_items, :subscription_frequency, :string

    unless reverting?
      say_with_time("updating records") do
        Boutique::Product::Subscription.find_each do |product|
          Boutique::LineItem.where(product_variant_id: product.variants.select(:id))
                            .where.not(unit_price: nil)
                            .update_all(subscription_frequency: product.subscription_frequency)
        end
      end
    end
  end
end
