# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_04_06_152021) do
  create_sequence "wipify_orders_base_number_seq"

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "wipify_line_items", force: :cascade do |t|
    t.bigint "wipify_order_id", null: false
    t.integer "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "wipify_product_variant_id", null: false
    t.index ["wipify_order_id"], name: "index_wipify_line_items_on_wipify_order_id"
    t.index ["wipify_product_variant_id"], name: "index_wipify_line_items_on_wipify_product_variant_id"
  end

  create_table "wipify_orders", force: :cascade do |t|
    t.string "customer_type"
    t.bigint "customer_id"
    t.integer "base_number"
    t.string "number"
    t.string "email"
    t.string "aasm_state", default: "pending"
    t.integer "line_items_count", default: 0
    t.integer "line_items_price"
    t.integer "shipping_method_price"
    t.integer "payment_method_price"
    t.integer "total_price"
    t.datetime "confirmed_at"
    t.datetime "paid_at"
    t.datetime "dispatched_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "wipify_shipping_method_id"
    t.bigint "wipify_payment_method_id"
    t.index ["customer_type", "customer_id"], name: "index_wipify_orders_on_customer"
    t.index ["number"], name: "index_wipify_orders_on_number"
    t.index ["wipify_payment_method_id"], name: "index_wipify_orders_on_wipify_payment_method_id"
    t.index ["wipify_shipping_method_id"], name: "index_wipify_orders_on_wipify_shipping_method_id"
  end

  create_table "wipify_payment_methods", force: :cascade do |t|
    t.string "title"
    t.string "type"
    t.text "description"
    t.string "price"
    t.integer "position"
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_wipify_payment_methods_on_position"
    t.index ["published"], name: "index_wipify_payment_methods_on_published", where: "(published = true)"
  end

  create_table "wipify_product_variants", force: :cascade do |t|
    t.bigint "wipify_product_id", null: false
    t.string "title"
    t.integer "price", null: false
    t.boolean "master", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master"], name: "index_wipify_product_variants_on_master", where: "(master = true)"
    t.index ["wipify_product_id"], name: "index_wipify_product_variants_on_wipify_product_id"
  end

  create_table "wipify_products", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "wipify_shipping_methods", force: :cascade do |t|
    t.string "title"
    t.string "type"
    t.text "description"
    t.string "price"
    t.integer "position"
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_wipify_shipping_methods_on_position"
    t.index ["published"], name: "index_wipify_shipping_methods_on_published", where: "(published = true)"
  end

  add_foreign_key "wipify_line_items", "wipify_orders"
  add_foreign_key "wipify_line_items", "wipify_product_variants"
  add_foreign_key "wipify_orders", "wipify_payment_methods"
  add_foreign_key "wipify_orders", "wipify_shipping_methods"
  add_foreign_key "wipify_product_variants", "wipify_products"
end
