# frozen_string_literal: true

class CreateBoutiqueVouchers < ActiveRecord::Migration[7.0]
  def change
    create_table :boutique_vouchers do |t|
      t.string :code
      t.string :code_prefix, limit: 8
      t.string :title
      t.integer :discount
      t.boolean :discount_in_percentages, default: false
      t.integer :number_of_allowed_uses
      t.integer :use_count, default: 0

      t.boolean :published, default: false
      t.datetime :published_from
      t.datetime :published_until

      t.timestamps
    end

    add_index :boutique_vouchers, "upper(code)", name: "index_boutique_vouchers_on_upper_code", unique: true
    add_index :boutique_vouchers, :published
    add_index :boutique_vouchers, :published_from
    add_index :boutique_vouchers, :published_until
  end
end
