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

ActiveRecord::Schema.define(version: 20190925110227) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"
  enable_extension "pg_trgm"

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

  add_index "addresses", ["addressable_id", "addressable_type"], name: "index_addresses_on_addressable_id_and_addressable_type", using: :btree
  add_index "addresses", ["district_id"], name: "index_addresses_on_district_id", using: :btree

  create_table "appointment_slot_presets", force: :cascade do |t|
    t.integer "day"
    t.integer "hours"
    t.integer "minutes"
    t.integer "quota"
  end

  create_table "appointment_slots", force: :cascade do |t|
    t.datetime "timestamp"
    t.integer  "quota"
    t.string   "note",      default: ""
  end

  create_table "auth_tokens", force: :cascade do |t|
    t.datetime "otp_code_expiry"
    t.string   "otp_secret_key",  limit: 255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "otp_auth_key",    limit: 30
  end

  add_index "auth_tokens", ["user_id"], name: "index_auth_tokens_on_user_id", using: :btree

  create_table "beneficiaries", force: :cascade do |t|
    t.integer  "identity_type_id"
    t.integer  "created_by_id"
    t.string   "identity_number"
    t.string   "title"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone_number"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "beneficiaries", ["created_by_id"], name: "index_beneficiaries_on_created_by_id", using: :btree
  add_index "beneficiaries", ["identity_type_id"], name: "index_beneficiaries_on_identity_type_id", using: :btree

  create_table "booking_types", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "identifier"
  end

  add_index "booking_types", ["identifier"], name: "index_booking_types_on_identifier", using: :btree

  create_table "boxes", force: :cascade do |t|
    t.string   "box_number"
    t.string   "description"
    t.text     "comments"
    t.integer  "pallet_id"
    t.integer  "stockit_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "boxes", ["pallet_id"], name: "index_boxes_on_pallet_id", using: :btree

  create_table "cancellation_reasons", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "visible_to_admin", default: true
  end

  create_table "companies", force: :cascade do |t|
    t.string   "name"
    t.integer  "crm_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "updated_by_id"
  end

  create_table "computer_accessories", force: :cascade do |t|
    t.string   "brand"
    t.string   "model"
    t.string   "serial_num"
    t.integer  "country_id"
    t.string   "size"
    t.string   "interface"
    t.string   "comp_voltage"
    t.string   "comp_test_status"
    t.integer  "updated_by_id"
    t.integer  "stockit_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "computers", force: :cascade do |t|
    t.string   "brand"
    t.string   "model"
    t.string   "serial_num"
    t.integer  "country_id"
    t.string   "size"
    t.string   "cpu"
    t.string   "ram"
    t.string   "hdd"
    t.string   "optical"
    t.string   "video"
    t.string   "sound"
    t.string   "lan"
    t.string   "wireless"
    t.string   "usb"
    t.string   "comp_voltage"
    t.string   "comp_test_status"
    t.string   "os"
    t.string   "os_serial_num"
    t.string   "ms_office_serial_num"
    t.string   "mar_os_serial_num"
    t.string   "mar_ms_office_serial_num"
    t.integer  "updated_by_id"
    t.integer  "stockit_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "mobile",     limit: 255
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
    t.string   "name_en",        limit: 255
    t.string   "name_zh_tw",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cost"
    t.float    "truck_size"
    t.boolean  "is_van_allowed",             default: true
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

  add_index "deliveries", ["contact_id"], name: "index_deliveries_on_contact_id", using: :btree
  add_index "deliveries", ["gogovan_order_id"], name: "index_deliveries_on_gogovan_order_id", using: :btree
  add_index "deliveries", ["offer_id"], name: "index_deliveries_on_offer_id", using: :btree
  add_index "deliveries", ["schedule_id"], name: "index_deliveries_on_schedule_id", using: :btree

  create_table "districts", force: :cascade do |t|
    t.string   "name_en",      limit: 255
    t.string   "name_zh_tw",   limit: 255
    t.integer  "territory_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
  end

  add_index "districts", ["territory_id"], name: "index_districts_on_territory_id", using: :btree

  create_table "donor_conditions", force: :cascade do |t|
    t.string   "name_en",    limit: 255
    t.string   "name_zh_tw", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "electricals", force: :cascade do |t|
    t.string   "brand"
    t.string   "model"
    t.string   "serial_number"
    t.integer  "country_id"
    t.string   "standard"
    t.string   "voltage"
    t.string   "frequency"
    t.string   "power"
    t.string   "system_or_region"
    t.string   "test_status"
    t.date     "tested_on"
    t.integer  "updated_by_id"
    t.integer  "stockit_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "gogovan_orders", force: :cascade do |t|
    t.integer  "booking_id"
    t.string   "status",         limit: 255
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
    t.string   "name_en",    limit: 255
    t.string   "name_zh_tw", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "disabled",               default: false
  end

  create_table "goodcity_requests", force: :cascade do |t|
    t.integer  "quantity"
    t.integer  "package_type_id"
    t.integer  "order_id"
    t.text     "description"
    t.integer  "created_by_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "goodcity_requests", ["created_by_id"], name: "index_goodcity_requests_on_created_by_id", using: :btree
  add_index "goodcity_requests", ["order_id"], name: "index_goodcity_requests_on_order_id", using: :btree
  add_index "goodcity_requests", ["package_type_id"], name: "index_goodcity_requests_on_package_type_id", using: :btree

  create_table "goodcity_settings", force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.string "description"
  end

  add_index "goodcity_settings", ["key"], name: "index_goodcity_settings_on_key", using: :btree

  create_table "holidays", force: :cascade do |t|
    t.datetime "holiday"
    t.integer  "year"
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "identity_types", force: :cascade do |t|
    t.string   "identifier"
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "images", force: :cascade do |t|
    t.string   "cloudinary_id",  limit: 255
    t.boolean  "favourite",                  default: false
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "angle",                      default: 0
    t.integer  "imageable_id"
    t.string   "imageable_type"
  end

  add_index "images", ["imageable_id", "imageable_type"], name: "index_images_on_imageable_id_and_imageable_type", using: :btree

  create_table "inventory_numbers", force: :cascade do |t|
    t.string "code"
  end

  create_table "items", force: :cascade do |t|
    t.text     "donor_description"
    t.string   "state",               limit: 255
    t.integer  "offer_id",                        null: false
    t.integer  "package_type_id"
    t.integer  "rejection_reason_id"
    t.string   "reject_reason",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "donor_condition_id"
    t.datetime "deleted_at"
    t.text     "rejection_comments"
  end

  add_index "items", ["donor_condition_id"], name: "index_items_on_donor_condition_id", using: :btree
  add_index "items", ["offer_id"], name: "index_items_on_offer_id", using: :btree
  add_index "items", ["package_type_id"], name: "index_items_on_package_type_id", using: :btree
  add_index "items", ["rejection_reason_id"], name: "index_items_on_rejection_reason_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "building"
    t.string   "area"
    t.integer  "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "locations", ["area"], name: "index_locations_on_area", using: :gin
  add_index "locations", ["building"], name: "index_locations_on_building", using: :gin
  add_index "locations", ["stockit_id"], name: "index_locations_on_stockit_id", using: :btree

  create_table "messages", force: :cascade do |t|
    t.text     "body"
    t.integer  "sender_id"
    t.boolean  "is_private", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "offer_id"
    t.integer  "item_id"
    t.integer  "order_id"
  end

  add_index "messages", ["body"], name: "messages_body_search_idx", using: :gin
  add_index "messages", ["item_id"], name: "index_messages_on_item_id", using: :btree
  add_index "messages", ["offer_id"], name: "index_messages_on_offer_id", using: :btree
  add_index "messages", ["order_id"], name: "index_messages_on_order_id", using: :btree
  add_index "messages", ["sender_id"], name: "index_messages_on_sender_id", using: :btree

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
    t.boolean  "saleable",                            default: false
    t.integer  "company_id"
  end

  add_index "offers", ["cancellation_reason_id"], name: "index_offers_on_cancellation_reason_id", using: :btree
  add_index "offers", ["closed_by_id"], name: "index_offers_on_closed_by_id", using: :btree
  add_index "offers", ["company_id"], name: "index_offers_on_company_id", using: :btree
  add_index "offers", ["created_by_id"], name: "index_offers_on_created_by_id", using: :btree
  add_index "offers", ["crossroads_transport_id"], name: "index_offers_on_crossroads_transport_id", using: :btree
  add_index "offers", ["gogovan_transport_id"], name: "index_offers_on_gogovan_transport_id", using: :btree
  add_index "offers", ["notes"], name: "offers_notes_search_idx", using: :gin
  add_index "offers", ["received_by_id"], name: "index_offers_on_received_by_id", using: :btree
  add_index "offers", ["reviewed_by_id"], name: "index_offers_on_reviewed_by_id", using: :btree
  add_index "offers", ["state"], name: "index_offers_on_state", using: :btree

  create_table "order_transports", force: :cascade do |t|
    t.datetime "scheduled_at"
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

  add_index "order_transports", ["contact_id"], name: "index_order_transports_on_contact_id", using: :btree
  add_index "order_transports", ["gogovan_order_id"], name: "index_order_transports_on_gogovan_order_id", using: :btree
  add_index "order_transports", ["gogovan_transport_id"], name: "index_order_transports_on_gogovan_transport_id", using: :btree
  add_index "order_transports", ["order_id"], name: "index_order_transports_on_order_id", using: :btree
  add_index "order_transports", ["scheduled_at"], name: "index_order_transports_on_scheduled_at", using: :btree

  create_table "orders", force: :cascade do |t|
    t.string   "status"
    t.string   "code"
    t.string   "detail_type"
    t.integer  "detail_id"
    t.integer  "stockit_contact_id"
    t.integer  "stockit_organisation_id"
    t.integer  "stockit_id"
    t.datetime "created_at"
    t.datetime "updated_at",                           null: false
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
    t.integer  "people_helped",           default: 0
    t.integer  "beneficiary_id"
    t.integer  "address_id"
    t.integer  "district_id"
    t.text     "cancellation_reason"
    t.integer  "booking_type_id"
    t.string   "staff_note",              default: ""
  end

  add_index "orders", ["address_id"], name: "index_orders_on_address_id", using: :btree
  add_index "orders", ["beneficiary_id"], name: "index_orders_on_beneficiary_id", using: :btree
  add_index "orders", ["cancelled_by_id"], name: "index_orders_on_cancelled_by_id", using: :btree
  add_index "orders", ["closed_by_id"], name: "index_orders_on_closed_by_id", using: :btree
  add_index "orders", ["code"], name: "orders_code_idx", using: :gin
  add_index "orders", ["country_id"], name: "index_orders_on_country_id", using: :btree
  add_index "orders", ["created_by_id"], name: "index_orders_on_created_by_id", using: :btree
  add_index "orders", ["detail_id", "detail_type"], name: "index_orders_on_detail_id_and_detail_type", using: :btree
  add_index "orders", ["detail_id"], name: "index_orders_on_detail_id", using: :btree
  add_index "orders", ["dispatch_started_by_id"], name: "index_orders_on_dispatch_started_by_id", using: :btree
  add_index "orders", ["organisation_id"], name: "index_orders_on_organisation_id", using: :btree
  add_index "orders", ["process_completed_by_id"], name: "index_orders_on_process_completed_by_id", using: :btree
  add_index "orders", ["processed_by_id"], name: "index_orders_on_processed_by_id", using: :btree
  add_index "orders", ["state"], name: "index_orders_on_state", using: :btree
  add_index "orders", ["stockit_activity_id"], name: "index_orders_on_stockit_activity_id", using: :btree
  add_index "orders", ["stockit_contact_id"], name: "index_orders_on_stockit_contact_id", using: :btree
  add_index "orders", ["stockit_organisation_id"], name: "index_orders_on_stockit_organisation_id", using: :btree
  add_index "orders", ["submitted_by_id"], name: "index_orders_on_submitted_by_id", using: :btree

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

  add_index "orders_packages", ["order_id", "package_id"], name: "index_orders_packages_on_order_id_and_package_id", using: :btree
  add_index "orders_packages", ["order_id"], name: "index_orders_packages_on_order_id", using: :btree
  add_index "orders_packages", ["package_id", "order_id"], name: "index_orders_packages_on_package_id_and_order_id", using: :btree
  add_index "orders_packages", ["package_id"], name: "index_orders_packages_on_package_id", using: :btree
  add_index "orders_packages", ["updated_by_id"], name: "index_orders_packages_on_updated_by_id", using: :btree

  create_table "orders_process_checklists", force: :cascade do |t|
    t.integer "order_id"
    t.integer "process_checklist_id"
  end

  add_index "orders_process_checklists", ["order_id"], name: "index_orders_process_checklists_on_order_id", using: :btree
  add_index "orders_process_checklists", ["process_checklist_id"], name: "index_orders_process_checklists_on_process_checklist_id", using: :btree

  create_table "orders_purposes", force: :cascade do |t|
    t.integer "order_id"
    t.integer "purpose_id"
  end

  add_index "orders_purposes", ["order_id"], name: "index_orders_purposes_on_order_id", using: :btree
  add_index "orders_purposes", ["purpose_id"], name: "index_orders_purposes_on_purpose_id", using: :btree

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
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "preferred_contact_number"
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
    t.boolean  "allow_requests",     default: true
    t.boolean  "allow_stock",        default: false
    t.boolean  "allow_pieces",       default: false
    t.string   "subform"
  end

  add_index "package_types", ["allow_requests"], name: "index_package_types_on_allow_requests", using: :btree
  add_index "package_types", ["location_id"], name: "index_package_types_on_location_id", using: :btree
  add_index "package_types", ["name_en"], name: "package_types_name_en_search_idx", using: :gin
  add_index "package_types", ["name_zh_tw"], name: "package_types_name_zh_tw_search_idx", using: :gin
  add_index "package_types", ["stockit_id"], name: "index_package_types_on_stockit_id", using: :btree
  add_index "package_types", ["visible_in_selects"], name: "index_package_types_on_visible_in_selects", using: :btree

  create_table "packages", force: :cascade do |t|
    t.integer  "quantity"
    t.integer  "length"
    t.integer  "width"
    t.integer  "height"
    t.text     "notes"
    t.integer  "item_id"
    t.string   "state",                    limit: 255
    t.datetime "received_at"
    t.datetime "rejected_at"
    t.integer  "package_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "offer_id",                             default: 0
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
    t.boolean  "saleable",                             default: false
    t.integer  "set_item_id"
    t.string   "case_number"
    t.boolean  "allow_web_publish"
    t.integer  "received_quantity"
    t.integer  "weight"
    t.integer  "pieces"
    t.integer  "detail_id"
    t.string   "detail_type"
  end

  add_index "packages", ["allow_web_publish"], name: "index_packages_on_allow_web_publish", using: :btree
  add_index "packages", ["box_id"], name: "index_packages_on_box_id", using: :btree
  add_index "packages", ["case_number"], name: "index_packages_on_case_number", using: :gin
  add_index "packages", ["designation_name"], name: "index_packages_on_designation_name", using: :gin
  add_index "packages", ["detail_type", "detail_id"], name: "index_packages_on_detail_type_and_detail_id", using: :btree
  add_index "packages", ["donor_condition_id"], name: "index_packages_on_donor_condition_id", using: :btree
  add_index "packages", ["inventory_number"], name: "inventory_numbers_search_idx", using: :gin
  add_index "packages", ["item_id"], name: "index_packages_on_item_id", using: :btree
  add_index "packages", ["location_id"], name: "index_packages_on_location_id", using: :btree
  add_index "packages", ["notes"], name: "index_packages_on_notes", using: :gin
  add_index "packages", ["offer_id"], name: "index_packages_on_offer_id", using: :btree
  add_index "packages", ["order_id"], name: "index_packages_on_order_id", using: :btree
  add_index "packages", ["package_type_id"], name: "index_packages_on_package_type_id", using: :btree
  add_index "packages", ["pallet_id"], name: "index_packages_on_pallet_id", using: :btree
  add_index "packages", ["quantity"], name: "partial_index_quantity_greater_than_zero", where: "(quantity > 0)", using: :btree
  add_index "packages", ["set_item_id"], name: "index_packages_on_set_item_id", using: :btree
  add_index "packages", ["state"], name: "index_packages_on_state", using: :gin
  add_index "packages", ["stockit_designated_by_id"], name: "index_packages_on_stockit_designated_by_id", using: :btree
  add_index "packages", ["stockit_id"], name: "index_packages_on_stockit_id", using: :btree
  add_index "packages", ["stockit_moved_by_id"], name: "index_packages_on_stockit_moved_by_id", using: :btree
  add_index "packages", ["stockit_sent_by_id"], name: "index_packages_on_stockit_sent_by_id", using: :btree

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
  add_index "packages_locations", ["package_id", "location_id"], name: "index_packages_locations_on_package_id_and_location_id", using: :btree
  add_index "packages_locations", ["package_id"], name: "index_packages_locations_on_package_id", using: :btree
  add_index "packages_locations", ["reference_to_orders_package"], name: "index_packages_locations_on_reference_to_orders_package", using: :btree

  create_table "pallets", force: :cascade do |t|
    t.string   "pallet_number"
    t.string   "description"
    t.text     "comments"
    t.integer  "stockit_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "process_checklists", force: :cascade do |t|
    t.string  "text_en"
    t.string  "text_zh_tw"
    t.integer "booking_type_id"
  end

  add_index "process_checklists", ["booking_type_id"], name: "index_process_checklists_on_booking_type_id", using: :btree

  create_table "purposes", force: :cascade do |t|
    t.string   "name_en"
    t.string   "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "identifier"
  end

  create_table "rejection_reasons", force: :cascade do |t|
    t.string   "name_en",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name_zh_tw", limit: 255
  end

  create_table "requested_packages", force: :cascade do |t|
    t.integer "user_id"
    t.integer "package_id"
    t.boolean "is_available"
  end

  add_index "requested_packages", ["package_id", "user_id"], name: "index_requested_packages_on_package_id_and_user_id", unique: true, using: :btree
  add_index "requested_packages", ["package_id"], name: "index_requested_packages_on_package_id", using: :btree
  add_index "requested_packages", ["user_id", "package_id"], name: "index_requested_packages_on_user_id_and_package_id", unique: true, using: :btree
  add_index "requested_packages", ["user_id"], name: "index_requested_packages_on_user_id", using: :btree

  create_table "role_permissions", force: :cascade do |t|
    t.integer  "role_id"
    t.integer  "permission_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "role_permissions", ["permission_id"], name: "index_role_permissions_on_permission_id", using: :btree
  add_index "role_permissions", ["role_id"], name: "index_role_permissions_on_role_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  add_index "subpackage_types", ["package_type_id", "package_type_id"], name: "index_subpackage_types_on_package_type_id_and_package_type_id", using: :btree
  add_index "subpackage_types", ["package_type_id"], name: "index_subpackage_types_on_package_type_id", using: :btree
  add_index "subpackage_types", ["subpackage_type_id"], name: "index_subpackage_types_on_subpackage_type_id", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer "offer_id"
    t.integer "user_id"
    t.integer "message_id"
    t.string  "state",      limit: 255
    t.integer "order_id"
  end

  add_index "subscriptions", ["message_id"], name: "index_subscriptions_on_message_id", using: :btree
  add_index "subscriptions", ["offer_id", "user_id", "message_id"], name: "offer_user_message", unique: true, using: :btree
  add_index "subscriptions", ["offer_id"], name: "index_subscriptions_on_offer_id", using: :btree
  add_index "subscriptions", ["order_id"], name: "index_subscriptions_on_order_id", using: :btree
  add_index "subscriptions", ["state"], name: "index_subscriptions_on_state", using: :btree
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

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

  create_table "user_roles", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_roles", ["role_id"], name: "index_user_roles_on_role_id", using: :btree
  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "first_name",           limit: 255
    t.string   "last_name",            limit: 255
    t.string   "mobile",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "image_id"
    t.datetime "last_connected"
    t.datetime "last_disconnected"
    t.boolean  "disabled",                         default: false
    t.string   "email"
    t.string   "title"
    t.datetime "sms_reminder_sent_at"
    t.boolean  "is_mobile_verified",               default: false
    t.boolean  "is_email_verified",                default: false
    t.boolean  "receive_email",                    default: false
    t.string   "other_phone"
  end

  add_index "users", ["image_id"], name: "index_users_on_image_id", using: :btree
  add_index "users", ["mobile"], name: "index_users_on_mobile", using: :btree
  add_index "users", ["sms_reminder_sent_at"], name: "index_users_on_sms_reminder_sent_at", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.jsonb    "object"
    t.jsonb    "object_changes"
    t.integer  "related_id"
    t.string   "related_type"
    t.datetime "created_at"
  end

  add_index "versions", ["created_at", "whodunnit"], name: "partial_index_recent_locations", where: "(((event)::text = ANY (ARRAY[('create'::character varying)::text, ('update'::character varying)::text])) AND (object_changes ? 'location_id'::text))", using: :btree
  add_index "versions", ["created_at"], name: "index_versions_on_created_at", using: :btree
  add_index "versions", ["event"], name: "index_versions_on_event", using: :btree
  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["item_type"], name: "index_versions_on_item_type", using: :btree
  add_index "versions", ["related_type", "related_id"], name: "index_versions_on_related_type_and_related_id", using: :btree
  add_index "versions", ["related_type"], name: "index_versions_on_related_type", using: :btree
  add_index "versions", ["whodunnit"], name: "index_versions_on_whodunnit", using: :btree

  add_foreign_key "beneficiaries", "identity_types"
  add_foreign_key "goodcity_requests", "orders"
  add_foreign_key "goodcity_requests", "package_types"
  add_foreign_key "messages", "orders"
  add_foreign_key "orders_process_checklists", "orders"
  add_foreign_key "orders_process_checklists", "process_checklists"
  add_foreign_key "organisations", "countries"
  add_foreign_key "organisations", "districts"
  add_foreign_key "organisations", "organisation_types"
  add_foreign_key "organisations_users", "organisations"
  add_foreign_key "organisations_users", "users"
  add_foreign_key "process_checklists", "booking_types"
  add_foreign_key "subscriptions", "orders"
end
