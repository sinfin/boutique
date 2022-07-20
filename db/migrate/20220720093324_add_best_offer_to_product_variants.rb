# frozen_string_literal: true

class AddBestOfferToProductVariants < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_product_variants, :best_offer, :boolean, default: false
  end
end
