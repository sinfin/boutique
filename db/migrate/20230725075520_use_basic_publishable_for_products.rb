# frozen_string_literal: true

class UseBasicPublishableForProducts < ActiveRecord::Migration[7.0]
  def change
    remove_column :boutique_products, :published_at, :datetime
  end
end
