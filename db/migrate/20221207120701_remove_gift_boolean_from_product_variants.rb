# frozen_string_literal: true

class RemoveGiftBooleanFromProductVariants < ActiveRecord::Migration[7.0]
  def change
    remove_column :boutique_product_variants, :gift, :boolean, default: false
  end
end
