# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20141230081658) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string   "flat",             limit: 255
    t.string   "building",         limit: 255
    t.string   "street",           limit: 255
    t.integer  "district_id"
    t.integer  "addressable_id"
    t.string   "addressable_type", limit: 255
    t.string   "address_type",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "auth_tokens", force: :cascade do |t|
    t.datetime "otp_code_expiry"
    t.string   "otp_secret_key",  limit: 255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "otp_auth_key",    limit: 30
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "mobile",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "crossroads_transports", force: :cascade do |t|
    t.string   "name_en",    limit: 255
    t.string   "name_zh_tw", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deliveries", force: :cascade do |t|
    t.integer  "offer_id"
    t.integer  "contact_id"
    t.integer  "schedule_id"
    t.string   "delivery_type",    limit: 255
    t.datetime "start"
    t.datetime "finish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gogovan_order_id"
    t.datetime "deleted_at"
  end

  create_table "districts", force: :cascade do |t|
    t.string   "name_en",      limit: 255
    t.string   "name_zh_tw",   limit: 255
    t.integer  "territory_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
  end

  create_table "donor_conditions", force: :cascade do |t|
    t.string   "name_en",    limit: 255
    t.string   "name_zh_tw", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gogovan_orders", force: :cascade do |t|
    t.integer  "booking_id"
    t.string   "status",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "gogovan_transports", force: :cascade do |t|
    t.string   "name_en",    limit: 255
    t.string   "name_zh_tw", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "holidays", force: :cascade do |t|
    t.datetime "holiday"
    t.integer  "year"
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", force: :cascade do |t|
    t.string   "cloudinary_id", limit: 255
    t.boolean  "favourite",                 default: false
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "item_types", force: :cascade do |t|
    t.string   "name_en",           limit: 255
    t.string   "code",              limit: 255
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name_zh_tw",        limit: 255
    t.boolean  "is_item_type_node",             default: false, null: false
  end

  create_table "items", force: :cascade do |t|
    t.text     "donor_description"
    t.string   "state",               limit: 255
    t.integer  "offer_id",                                        null: false
    t.integer  "item_type_id"
    t.integer  "rejection_reason_id"
    t.string   "reject_reason",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "saleable",                        default: false
    t.integer  "donor_condition_id"
    t.datetime "deleted_at"
    t.string   "rejection_comments",  limit: 255
  end

  create_table "messages", force: :cascade do |t|
    t.text     "body"
    t.integer  "sender_id"
    t.boolean  "is_private", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "offer_id"
    t.integer  "item_id"
  end

  create_table "offers", force: :cascade do |t|
    t.string   "language",                limit: 255
    t.string   "state",                   limit: 255
    t.string   "origin",                  limit: 255
    t.boolean  "stairs"
    t.boolean  "parking"
    t.string   "estimated_size",          limit: 255
    t.text     "notes"
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.datetime "submitted_at"
    t.integer  "reviewed_by_id"
    t.datetime "reviewed_at"
    t.integer  "gogovan_transport_id"
    t.integer  "crossroads_transport_id"
  end

  create_table "packages", force: :cascade do |t|
    t.integer  "quantity"
    t.integer  "length"
    t.integer  "width"
    t.integer  "height"
    t.text     "notes"
    t.integer  "item_id"
    t.string   "state",           limit: 255
    t.datetime "received_at"
    t.datetime "rejected_at"
    t.integer  "package_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rejection_reasons", force: :cascade do |t|
    t.string   "name_en",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name_zh_tw", limit: 255
  end

  create_table "schedules", force: :cascade do |t|
    t.string   "resource",     limit: 255
    t.integer  "slot"
    t.string   "slot_name",    limit: 255
    t.string   "zone",         limit: 255
    t.datetime "scheduled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "offer_id"
    t.integer "user_id"
    t.integer "message_id"
    t.string  "state",      limit: 255
  end

  add_index "subscriptions", ["offer_id", "user_id", "message_id"], name: "offer_user_message", unique: true, using: :btree

  create_table "territories", force: :cascade do |t|
    t.string   "name_en",    limit: 255
    t.string   "name_zh_tw", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timeslots", force: :cascade do |t|
    t.string   "name_en",    limit: 255
    t.string   "name_zh_tw", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name",    limit: 255
    t.string   "last_name",     limit: 255
    t.string   "mobile",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "permission_id"
    t.integer  "image_id"
  end

  add_index "users", ["mobile"], name: "index_users_on_mobile", unique: true, using: :btree
  add_index "users", ["permission_id"], name: "index_users_on_permission_id", using: :btree

end
