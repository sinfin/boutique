# frozen_string_literal: true

class MoveColumnsFromProductVariantToProduct < ActiveRecord::Migration[7.0]
  COLUMNS_TO_MOVE = {
    code: { type: :string, limit: 32 },
    checkout_sidebar_content: { type: :text },
    description: { type: :text },
    subscription_period: { type: :integer, default: 12 },
    regular_price: { type: :integer },
    discounted_price: { type: :integer },
    discounted_from: { type: :datetime },
    discounted_until: { type: :datetime },
    best_offer: { type: :boolean, default: false },
  }

  def up
    COLUMNS_TO_MOVE.each do |column_name, options|
      add_column :boutique_products, column_name, options.delete(:type), **options
    end

    add_reference :boutique_line_items, :product, foreign_key: { to_table: :boutique_products }
    rename_column :boutique_line_items, :boutique_product_variant_id, :product_variant_id
    change_column_null :boutique_line_items, :product_variant_id, true

    say_with_time("updating models") do
      Boutique::ProductVariant.includes(:product).find_each do |variant|
        attrs = variant.attributes.symbolize_keys.slice(*COLUMNS_TO_MOVE.keys)

        variant.product.update_columns(attrs)
      end

      FriendlyId::Slug.where(sluggable_type: "Boutique::ProductVariant").destroy_all

      Boutique::LineItem.includes(:product_variant).find_each do |line_item|
        next if line_item.product_variant.nil?

        line_item.update_columns(product_id: line_item.product_variant.boutique_product_id)
      end
    end

    COLUMNS_TO_MOVE.each do |column_name, options|
      remove_column :boutique_product_variants, column_name, options.delete(:type), **options
    end

    remove_index :boutique_product_variants, :slug
    remove_column :boutique_product_variants, :slug, :string

    rename_column :boutique_vouchers, :product_variant_code, :product_code
  end

  def down
    COLUMNS_TO_MOVE.each do |column_name, options|
      add_column :boutique_product_variants, column_name, options.delete(:type), **options
    end

    say_with_time("updating models") do
      Boutique::ProductVariant.includes(:product).find_each do |variant|
        attrs = variant.product.attributes.symbolize_keys.slice(*COLUMNS_TO_MOVE.keys)

        variant.update_columns(attrs)
      end
    end

    remove_reference :boutique_line_items, :product
    rename_column :boutique_line_items, :product_variant_id, :boutique_product_variant_id

    add_column :boutique_product_variants, :slug, :string
    add_index :boutique_product_variants, :slug

    COLUMNS_TO_MOVE.each do |column_name, options|
      remove_column :boutique_products, column_name, options.delete(:type), **options
    end

    rename_column :boutique_vouchers, :product_code, :product_variant_code
  end
end
