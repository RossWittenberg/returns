# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170608182255) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "line_items", force: :cascade do |t|
    t.string   "variant_id"
    t.string   "product_id"
    t.text     "return_reason"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "lively_refund_id"
    t.integer  "quantity"
    t.float    "sub_total"
    t.float    "total_tax"
    t.integer  "quality"
    t.index ["lively_refund_id"], name: "index_line_items_on_lively_refund_id", using: :btree
  end

  create_table "lively_refunds", force: :cascade do |t|
    t.string   "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shops", force: :cascade do |t|
    t.string   "shopify_domain", null: false
    t.string   "shopify_token",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true, using: :btree
  end

end
