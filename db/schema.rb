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

ActiveRecord::Schema.define(version: 20140628072714) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "images", force: true do |t|
    t.integer  "order"
    t.string   "image"
    t.boolean  "favourite"
    t.string   "parent_type"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_types", force: true do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", force: true do |t|
    t.text     "donor_description"
    t.string   "donor_condition"
    t.string   "state"
    t.integer  "offer_id"
    t.integer  "item_type_id"
    t.integer  "rejection_reason_id"
    t.string   "rejection_other_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", force: true do |t|
    t.text     "body"
    t.string   "recipient_type"
    t.integer  "recipient_id"
    t.integer  "sender_id"
    t.boolean  "private"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "offers", force: true do |t|
    t.string   "language"
    t.string   "state"
    t.string   "collection_contact_name"
    t.string   "collection_contact_phone"
    t.string   "origin"
    t.boolean  "stairs"
    t.boolean  "parking"
    t.string   "estimated_size"
    t.text     "notes"
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  create_table "permissions", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions_users", id: false, force: true do |t|
    t.integer "permission_id"
    t.integer "user_id"
  end

  add_index "permissions_users", ["permission_id", "user_id"], name: "index_permissions_users_on_permission_id_and_user_id", unique: true, using: :btree

  create_table "rejection_reasons", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
