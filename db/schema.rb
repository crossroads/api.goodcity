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

ActiveRecord::Schema.define(version: 20180827034143) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"
  enable_extension "pg_trgm"

  create_table "addresses", force: :cascade do |t|
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

  create_table "auth_tokens", force: :cascade do |t|
    t.datetime "otp_code_expiry"
    t.string   "otp_secret_key"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "otp_auth_key",    limit: 30
  end

  create_table "boxes", force: :cascade do |t|
    t.string   "box_number"
    t.string   "description"
    t.text     "comments"
    t.integer  "pallet_id"
    t.integer  "stockit_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "braintree_transactions", force: :cascade do |t|
    t.string   "transaction_id"
    t.integer  "customer_id"
    t.decimal  "amount"
    t.string   "status"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.boolean  "is_success"
  end

  create_table "cancellation_reasons", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "visible_to_admin", default: true
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "name"
    t.string   "mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "countries", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.integer  "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "crossroads_transports", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cost"
    t.float    "truck_size"
    t.boolean  "is_van_allowed", default: true
  end

  create_table "deliveries", force: :cascade do |t|
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

  create_table "districts", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.integer  "territory_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
  end

  create_table "donor_conditions", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gogovan_orders", force: :cascade do |t|
    t.integer  "booking_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.float    "price"
    t.string   "driver_name"
    t.string   "driver_mobile"
    t.string   "driver_license"
    t.string   "ggv_uuid"
    t.datetime "completed_at"
  end

  add_index "gogovan_orders", ["ggv_uuid"], name: "index_gogovan_orders_on_ggv_uuid", unique: true, using: :btree

  create_table "gogovan_transports", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "disabled",   default: false
  end

  create_table "holidays", force: :cascade do |t|
    t.datetime "holiday"
    t.integer  "year"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", force: :cascade do |t|
    t.string   "cloudinary_id"
    t.boolean  "favourite",      default: false
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "angle",          default: 0
    t.integer  "imageable_id"
    t.string   "imageable_type"
  end

  create_table "inventory_numbers", force: :cascade do |t|
    t.string "code"
  end

  create_table "items", force: :cascade do |t|
    t.text     "donor_description"
    t.string   "state"
    t.integer  "offer_id",            null: false
    t.integer  "package_type_id"
    t.integer  "rejection_reason_id"
    t.string   "reject_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "donor_condition_id"
    t.datetime "deleted_at"
    t.text     "rejection_comments"
  end

  create_table "locations", force: :cascade do |t|
    t.string   "building"
    t.string   "area"
    t.integer  "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.integer  "gogovan_transport_id"
    t.integer  "crossroads_transport_id"
    t.datetime "review_completed_at"
    t.datetime "received_at"
    t.string   "delivered_by",            limit: 30
    t.integer  "closed_by_id"
    t.datetime "cancelled_at"
    t.integer  "received_by_id"
    t.datetime "start_receiving_at"
    t.integer  "cancellation_reason_id"
    t.string   "cancel_reason"
    t.datetime "inactive_at"
    t.boolean  "saleable",                           default: false
  end

  create_table "order_transports", force: :cascade do |t|
    t.date     "scheduled_at"
    t.string   "timeslot"
    t.string   "transport_type"
    t.integer  "contact_id"
    t.integer  "gogovan_order_id"
    t.integer  "order_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "need_english",         default: false
    t.boolean  "need_cart",            default: false
    t.boolean  "need_carry",           default: false
    t.boolean  "need_over_6ft",        default: false
    t.integer  "gogovan_transport_id"
    t.string   "remove_net"
  end

  create_table "orders", force: :cascade do |t|
    t.string   "status"
    t.string   "code"
    t.string   "detail_type"
    t.integer  "detail_id"
    t.integer  "stockit_contact_id"
    t.integer  "stockit_organisation_id"
    t.integer  "stockit_id"
    t.datetime "created_at"
    t.datetime "updated_at",              null: false
    t.text     "description"
    t.integer  "stockit_activity_id"
    t.integer  "country_id"
    t.integer  "created_by_id"
    t.integer  "processed_by_id"
    t.integer  "organisation_id"
    t.string   "state"
    t.text     "purpose_description"
    t.datetime "processed_at"
    t.integer  "process_completed_by_id"
    t.datetime "process_completed_at"
    t.datetime "cancelled_at"
    t.integer  "cancelled_by_id"
    t.datetime "closed_at"
    t.integer  "closed_by_id"
    t.datetime "dispatch_started_at"
    t.integer  "dispatch_started_by_id"
    t.integer  "submitted_by_id"
    t.datetime "submitted_at"
  end

  add_index "orders", ["code"], name: "orders_code_idx", using: :gin

  create_table "orders_packages", force: :cascade do |t|
    t.integer  "package_id"
    t.integer  "order_id"
    t.string   "state"
    t.integer  "quantity"
    t.integer  "updated_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "sent_on"
  end

  create_table "orders_purposes", force: :cascade do |t|
    t.integer "order_id"
    t.integer "purpose_id"
  end

  create_table "organisation_types", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.string   "category_en"
    t.string   "category_zh_tw"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "organisations", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.integer  "organisation_type_id"
    t.text     "description_en"
    t.text     "description_zh_tw"
    t.string   "registration"
    t.string   "website"
    t.integer  "country_id"
    t.integer  "district_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "gih3_id"
  end

  add_index "organisations", ["country_id"], name: "index_organisations_on_country_id", using: :btree
  add_index "organisations", ["district_id"], name: "index_organisations_on_district_id", using: :btree
  add_index "organisations", ["organisation_type_id"], name: "index_organisations_on_organisation_type_id", using: :btree

  create_table "organisations_users", force: :cascade do |t|
    t.integer  "organisation_id"
    t.integer  "user_id"
    t.string   "position"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "organisations_users", ["organisation_id"], name: "index_organisations_users_on_organisation_id", using: :btree
  add_index "organisations_users", ["user_id"], name: "index_organisations_users_on_user_id", using: :btree

  create_table "package_categories", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.integer  "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "package_categories", ["parent_id"], name: "index_package_categories_on_parent_id", using: :btree

  create_table "package_categories_package_types", force: :cascade do |t|
    t.integer  "package_type_id"
    t.integer  "package_category_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "package_categories_package_types", ["package_category_id"], name: "index_package_categories_package_types_on_package_category_id", using: :btree
  add_index "package_categories_package_types", ["package_type_id"], name: "index_package_categories_package_types_on_package_type_id", using: :btree

  create_table "package_types", force: :cascade do |t|
    t.string   "code"
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.string   "other_terms_en"
    t.string   "other_terms_zh_tw"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "visible_in_selects", default: false
    t.integer  "stockit_id"
    t.integer  "location_id"
  end

  create_table "packages", force: :cascade do |t|
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
    t.integer  "offer_id",                 default: 0
    t.string   "inventory_number"
    t.integer  "location_id"
    t.string   "designation_name"
    t.integer  "donor_condition_id"
    t.string   "grade"
    t.integer  "box_id"
    t.integer  "pallet_id"
    t.integer  "stockit_id"
    t.integer  "order_id"
    t.date     "stockit_sent_on"
    t.date     "stockit_designated_on"
    t.integer  "stockit_designated_by_id"
    t.integer  "stockit_sent_by_id"
    t.integer  "favourite_image_id"
    t.date     "stockit_moved_on"
    t.integer  "stockit_moved_by_id"
    t.boolean  "saleable",                 default: false
    t.integer  "set_item_id"
    t.string   "case_number"
    t.boolean  "allow_web_publish"
    t.integer  "received_quantity"
  end

  add_index "packages", ["inventory_number"], name: "inventory_numbers_search_idx", using: :gin
  add_index "packages", ["stockit_id"], name: "index_packages_on_stockit_id", using: :btree

  create_table "packages_locations", force: :cascade do |t|
    t.integer  "package_id"
    t.integer  "location_id"
    t.integer  "quantity"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "reference_to_orders_package"
  end

  add_index "packages_locations", ["location_id", "package_id"], name: "index_packages_locations_on_location_id_and_package_id", using: :btree
  add_index "packages_locations", ["location_id"], name: "index_packages_locations_on_location_id", using: :btree
  add_index "packages_locations", ["package_id"], name: "index_packages_locations_on_package_id", using: :btree

  create_table "pallets", force: :cascade do |t|
    t.string   "pallet_number"
    t.string   "description"
    t.text     "comments"
    t.integer  "stockit_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "purposes", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rejection_reasons", force: :cascade do |t|
    t.string   "name_en"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name_zh_tw"
  end

  create_table "requests", force: :cascade do |t|
    t.integer  "quantity"
    t.integer  "package_type_id"
    t.integer  "order_id"
    t.text     "description"
    t.integer  "created_by_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "requests", ["order_id"], name: "index_requests_on_order_id", using: :btree
  add_index "requests", ["package_type_id"], name: "index_requests_on_package_type_id", using: :btree

  create_table "role_permissions", force: :cascade do |t|
    t.integer  "role_id"
    t.integer  "permission_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schedules", force: :cascade do |t|
    t.string   "resource"
    t.integer  "slot"
    t.string   "slot_name"
    t.string   "zone"
    t.datetime "scheduled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stockit_activities", force: :cascade do |t|
    t.string   "name"
    t.integer  "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stockit_contacts", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "mobile_phone_number"
    t.string   "phone_number"
    t.integer  "stockit_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "stockit_contacts", ["first_name"], name: "st_contacts_first_name_idx", using: :gin
  add_index "stockit_contacts", ["last_name"], name: "st_contacts_last_name_idx", using: :gin
  add_index "stockit_contacts", ["mobile_phone_number"], name: "st_contacts_mobile_phone_number_idx", using: :gin
  add_index "stockit_contacts", ["phone_number"], name: "st_contacts_phone_number_idx", using: :gin

  create_table "stockit_local_orders", force: :cascade do |t|
    t.string   "client_name"
    t.string   "hkid_number"
    t.string   "reference_number"
    t.integer  "stockit_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.text     "purpose_of_goods"
  end

  add_index "stockit_local_orders", ["client_name"], name: "st_local_orders_client_name_idx", using: :gin

  create_table "stockit_organisations", force: :cascade do |t|
    t.string   "name"
    t.integer  "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "stockit_organisations", ["name"], name: "st_organisations_name_idx", using: :gin

  create_table "subpackage_types", force: :cascade do |t|
    t.integer  "package_type_id"
    t.integer  "subpackage_type_id"
    t.boolean  "is_default",         default: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "offer_id"
    t.integer "user_id"
    t.integer "message_id"
    t.string  "state"
  end

  add_index "subscriptions", ["offer_id", "user_id", "message_id"], name: "offer_user_message", unique: true, using: :btree

  create_table "territories", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timeslots", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "permission_id"
    t.integer  "image_id"
    t.datetime "last_connected"
    t.datetime "last_disconnected"
    t.boolean  "disabled",          default: false
    t.string   "email"
  end

  add_index "users", ["mobile"], name: "index_users_on_mobile", unique: true, using: :btree
  add_index "users", ["permission_id"], name: "index_users_on_permission_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.json     "object"
    t.json     "object_changes"
    t.integer  "related_id"
    t.string   "related_type"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["related_id", "related_type"], name: "index_versions_on_related_id_and_related_type", using: :btree
  add_index "versions", ["whodunnit"], name: "index_versions_on_whodunnit", using: :btree

  add_foreign_key "organisations", "countries"
  add_foreign_key "organisations", "districts"
  add_foreign_key "organisations", "organisation_types"
  add_foreign_key "organisations_users", "organisations"
  add_foreign_key "organisations_users", "users"
  add_foreign_key "requests", "orders"
  add_foreign_key "requests", "package_types"
end
