# frozen_string_literal: true

class AddIntroPriceToBoutiqueProducts < ActiveRecord::Migration[7.0]
  def change
    # introductory subscription price; the on/off switch is a separate column so
    # that 0 can mean a free trial and so that the offer can be turned off
    # without losing the configured values
    add_column :boutique_products, :intro_enabled, :boolean, default: false
    add_column :boutique_products, :intro_price, :integer
    add_column :boutique_products, :intro_duration_months, :integer
  end
end
