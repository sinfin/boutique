# frozen_string_literal: true

class AddByQueryIndexToBoutiqueOrders < ActiveRecord::Migration[7.0]
  def change
    add_index :boutique_orders, %[(setweight(to_tsvector('simple', folio_unaccent(coalesce("boutique_orders"."number"::text, ''))), 'A') || setweight(to_tsvector('simple', folio_unaccent(coalesce("boutique_orders"."email"::text, ''))), 'B') || setweight(to_tsvector('simple', folio_unaccent(coalesce("boutique_orders"."first_name"::text, ''))), 'B') || setweight(to_tsvector('simple', folio_unaccent(coalesce("boutique_orders"."last_name"::text, ''))), 'B') || setweight(to_tsvector('simple', folio_unaccent(coalesce("boutique_orders"."invoice_number"::text, ''))), 'B'))], using: :gin, name: 'index_boutique_orders_on_by_query'
  end
end
