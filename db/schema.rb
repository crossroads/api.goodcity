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

ActiveRecord::Schema.define(version: 20141221110116) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: true do |t|
    t.string   "flat"
    t.string   "building"
    t.string   "street"
    t.integer  "district_id"
    t.integer  "addressable_id"
    t.string   "addressable_type"
    t.string   "address_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "auth_tokens", force: true do |t|
    t.datetime "otp_code_expiry"
    t.string   "otp_secret_key"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "otp_auth_key",    limit: 30
  end

  create_table "contacts", force: true do |t|
    t.string   "name"
    t.string   "mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "deliveries", force: true do |t|
    t.integer  "offer_id"
    t.integer  "contact_id"
    t.integer  "schedule_id"
    t.string   "delivery_type"
    t.datetime "start"
    t.datetime "finish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gogovan_order_id"
    t.datetime "deleted_at"
  end

  create_table "districts", force: true do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.integer  "territory_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
  end

  create_table "donor_conditions", force: true do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gogovan_orders", force: true do |t|
    t.integer  "booking_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "holidays", force: true do |t|
    t.datetime "holiday"
    t.integer  "year"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", force: true do |t|
    t.string   "cloudinary_id"
    t.boolean  "favourite",     default: false
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "item_types", force: true do |t|
    t.string   "name_en"
    t.string   "code"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name_zh_tw"
    t.boolean  "is_item_type_node", default: false, null: false
  end

  create_table "items", force: true do |t|
    t.text     "donor_description"
    t.string   "state"
    t.integer  "offer_id",                            null: false
    t.integer  "item_type_id"
    t.integer  "rejection_reason_id"
    t.string   "reject_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "saleable",            default: false
    t.integer  "donor_condition_id"
    t.datetime "deleted_at"
    t.string   "rejection_comments"
  end

  create_table "messages", force: true do |t|
    t.text     "body"
    t.integer  "sender_id"
    t.boolean  "is_private", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "offer_id"
    t.integer  "item_id"
  end

  create_table "offers", force: true do |t|
    t.string   "language"
    t.string   "state"
    t.string   "origin"
    t.boolean  "stairs"
    t.boolean  "parking"
    t.string   "estimated_size"
    t.text     "notes"
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.datetime "submitted_at"
    t.integer  "reviewed_by_id"
    t.datetime "reviewed_at"
    t.string   "gogovan_transport"
    t.string   "crossroads_transport"
  end

  create_table "packages", force: true do |t|
    t.integer  "quantity"
    t.integer  "length"
    t.integer  "width"
    t.integer  "height"
    t.text     "notes"
    t.integer  "item_id"
    t.string   "state"
    t.datetime "received_at"
    t.datetime "rejected_at"
    t.integer  "package_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "permissions", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rejection_reasons", force: true do |t|
    t.string   "name_en"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name_zh_tw"
  end

  create_table "schedules", force: true do |t|
    t.string   "resource"
    t.integer  "slot"
    t.string   "slot_name"
    t.string   "zone"
    t.datetime "scheduled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscriptions", force: true do |t|
    t.integer "offer_id"
    t.integer "user_id"
    t.integer "message_id"
    t.string  "state"
  end

  add_index "subscriptions", ["offer_id", "user_id", "message_id"], name: "offer_user_message", unique: true, using: :btree

  create_table "territories", force: true do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timeslots", force: true do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "permission_id"
  end

  add_index "users", ["mobile"], name: "index_users_on_mobile", unique: true, using: :btree
  add_index "users", ["permission_id"], name: "index_users_on_permission_id", using: :btree

end
