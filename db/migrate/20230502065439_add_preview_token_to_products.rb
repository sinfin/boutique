# frozen_string_literal: true

class AddPreviewTokenToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_products, :preview_token, :string

    unless reverting?
      say_with_time "Setting preview tokens" do
        Boutique::Product.find_each(&:reset_preview_token!)
      end
    end
  end
end
