# frozen_string_literal: true

class CreateBoutiqueVatRates < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_vat_rates do |t|
      t.integer :value
      t.string :title
      t.boolean :default, default: false

      t.timestamps
    end

    add_index :boutique_vat_rates, :value

    add_column :boutique_line_items, :vat_rate_value, :integer
    add_reference :boutique_products, :boutique_vat_rate, foreign_key: true

    if Boutique::Product.exists? && !reverting?
      say_with_time "seeding dummy default vat rate" do
        default = Boutique::VatRate.create!(title: "Dummy rate", value: 21, default: true)
        Boutique::Product.update_all(boutique_vat_rate_id: default.id)
        Boutique::LineItem.update_all(vat_rate_value: default.value)
        nil
      end
    end

    change_column_null :boutique_products, :boutique_vat_rate_id, false
  end
end
