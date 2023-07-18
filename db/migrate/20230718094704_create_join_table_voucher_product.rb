# frozen_string_literal: true

class CreateJoinTableVoucherProduct < ActiveRecord::Migration[7.0]
  def change
    create_join_table :vouchers, :products, table_name: :boutique_vouchers_products do |t|
      t.index [:voucher_id, :product_id]
      t.index [:product_id, :voucher_id]
    end

    add_foreign_key :boutique_vouchers_products, :boutique_vouchers, column: "voucher_id"
    add_foreign_key :boutique_vouchers_products, :boutique_products, column: "product_id"

    unless reverting?
      say_with_time "updating records" do
        Boutique::Voucher.where.not(product_variant_code: nil).find_each do |voucher|
          codes = product_variant_code.split(",").map(&:strip)
          voucher.products = Boutique::Product.joins(:variants).where(boutique_product_variants: { code: codes })
        end
      end
    end

    remove_column :boutique_vouchers, :product_variant_code, :string
  end
end
