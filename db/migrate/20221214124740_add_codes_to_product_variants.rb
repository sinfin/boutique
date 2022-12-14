# frozen_string_literal: true

class AddCodesToProductVariants < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_product_variants, :code, :string, limit: 32
    add_column :boutique_vouchers, :product_variant_code, :string

    unless reverting?
      Boutique::Product.includes(:variants).find_each.with_index do |product, i|
        # generate semirandom unique code to keep product variants valid
        product.variants.each do |variant|
          variant.update_column(:code, product.title.split(" ").map(&:first).join().parameterize.upcase + i.to_s)
        end
      end
    end
  end
end
