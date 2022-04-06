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

ActiveRecord::Schema[7.0].define(version: 2022_04_04_110239) do
  create_table "wipify_line_items", force: :cascade do |t|
    t.integer "wipify_order_id", null: false
    t.integer "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wipify_order_id"], name: "index_wipify_line_items_on_wipify_order_id"
  end

  create_table "wipify_orders", force: :cascade do |t|
    t.string "customer_type"
    t.integer "customer_id"
    t.integer "base_number"
    t.string "number"
    t.string "email"
    t.integer "line_items_count", default: 0
    t.integer "line_items_price"
    t.integer "total_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_type", "customer_id"], name: "index_wipify_orders_on_customer"
    t.index ["number"], name: "index_wipify_orders_on_number"
  end

  add_foreign_key "wipify_line_items", "aukceaukci_orders"
end
