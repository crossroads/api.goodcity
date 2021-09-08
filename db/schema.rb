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

ActiveRecord::Schema.define(version: 2021_09_08_110918) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "access_pass_roles", force: :cascade do |t|
    t.bigint "access_pass_id"
    t.bigint "role_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["access_pass_id"], name: "index_access_pass_roles_on_access_pass_id"
    t.index ["role_id"], name: "index_access_pass_roles_on_role_id"
  end

  create_table "access_passes", force: :cascade do |t|
    t.datetime "access_expires_at", precision: 6
    t.datetime "generated_at", precision: 6
    t.integer "generated_by_id"
    t.integer "access_key"
    t.bigint "printer_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["access_key"], name: "index_access_passes_on_access_key", unique: true
    t.index ["printer_id"], name: "index_access_passes_on_printer_id"
  end

  create_table "addresses", id: :serial, force: :cascade do |t|
    t.string "flat"
    t.string "building"
    t.string "street"
    t.integer "district_id"
    t.integer "addressable_id"
    t.string "addressable_type"
    t.string "address_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["addressable_id", "addressable_type"], name: "index_addresses_on_addressable_id_and_addressable_type"
    t.index ["district_id"], name: "index_addresses_on_district_id"
  end

  create_table "appointment_slot_presets", id: :serial, force: :cascade do |t|
    t.integer "day"
    t.integer "hours"
    t.integer "minutes"
    t.integer "quota"
  end

  create_table "appointment_slots", id: :serial, force: :cascade do |t|
    t.datetime "timestamp"
    t.integer "quota"
    t.string "note", default: ""
  end

  create_table "auth_tokens", id: :serial, force: :cascade do |t|
    t.datetime "otp_code_expiry"
    t.string "otp_secret_key"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "otp_auth_key", limit: 30
    t.index ["user_id"], name: "index_auth_tokens_on_user_id"
  end

  create_table "beneficiaries", id: :serial, force: :cascade do |t|
    t.integer "identity_type_id"
    t.integer "created_by_id"
    t.string "identity_number"
    t.string "title"
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_beneficiaries_on_created_by_id"
    t.index ["identity_type_id"], name: "index_beneficiaries_on_identity_type_id"
  end

  create_table "booking_types", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.index ["name_en", "name_zh_tw"], name: "index_booking_types_on_name_en_and_name_zh_tw", unique: true
  end

  create_table "boxes", id: :serial, force: :cascade do |t|
    t.string "box_number"
    t.string "description"
    t.text "comments"
    t.integer "pallet_id"
    t.integer "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pallet_id"], name: "index_boxes_on_pallet_id"
  end

  create_table "cancellation_reasons", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible_to_offer", default: true
    t.boolean "visible_to_order", default: false
  end

  create_table "canned_responses", force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.string "content_en"
    t.string "content_zh_tw"
    t.string "respondable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "message_type", default: "USER"
    t.string "guid"
    t.index ["guid"], name: "index_canned_responses_on_guid", unique: true
  end

  create_table "companies", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "crm_id"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "updated_by_id"
  end

  create_table "computer_accessories", id: :serial, force: :cascade do |t|
    t.string "brand"
    t.string "model"
    t.string "serial_num"
    t.integer "country_id"
    t.string "size"
    t.string "interface"
    t.string "comp_voltage"
    t.integer "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "comp_test_status_id"
  end

  create_table "computers", id: :serial, force: :cascade do |t|
    t.string "brand"
    t.string "model"
    t.string "serial_num"
    t.integer "country_id"
    t.string "size"
    t.string "cpu"
    t.string "ram"
    t.string "hdd"
    t.string "optical"
    t.string "video"
    t.string "sound"
    t.string "lan"
    t.string "wireless"
    t.string "usb"
    t.string "comp_voltage"
    t.string "os"
    t.string "os_serial_num"
    t.string "ms_office_serial_num"
    t.string "mar_os_serial_num"
    t.string "mar_ms_office_serial_num"
    t.integer "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "comp_test_status_id"
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "countries", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "preferred_region"
    t.string "preferred_sub_region"
    t.integer "m49"
    t.string "iso_alpha2"
    t.string "iso_alpha3"
    t.boolean "ldc", default: false
    t.boolean "lldc", default: false
    t.boolean "sids", default: false
    t.string "developing"
  end

  create_table "crossroads_transports", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "cost"
    t.float "truck_size"
    t.boolean "is_van_allowed", default: true
  end

  create_table "deliveries", id: :serial, force: :cascade do |t|
    t.integer "offer_id"
    t.integer "contact_id"
    t.integer "schedule_id"
    t.string "delivery_type"
    t.datetime "start"
    t.datetime "finish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "gogovan_order_id"
    t.datetime "deleted_at"
    t.index ["contact_id"], name: "index_deliveries_on_contact_id"
    t.index ["gogovan_order_id"], name: "index_deliveries_on_gogovan_order_id"
    t.index ["offer_id"], name: "index_deliveries_on_offer_id"
    t.index ["schedule_id"], name: "index_deliveries_on_schedule_id"
  end

  create_table "districts", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.integer "territory_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float "latitude"
    t.float "longitude"
    t.index ["territory_id"], name: "index_districts_on_territory_id"
  end

  create_table "donor_conditions", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "visible_to_donor", default: true, null: false
  end

  create_table "electricals", id: :serial, force: :cascade do |t|
    t.string "brand"
    t.string "model"
    t.string "serial_number"
    t.integer "country_id"
    t.string "standard"
    t.string "power"
    t.string "system_or_region"
    t.date "tested_on"
    t.integer "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test_status_id"
    t.integer "voltage_id"
    t.integer "frequency_id"
  end

  create_table "gogovan_orders", id: :serial, force: :cascade do |t|
    t.integer "booking_id"
    t.string "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.float "price"
    t.string "driver_name"
    t.string "driver_mobile"
    t.string "driver_license"
    t.string "ggv_uuid"
    t.datetime "completed_at"
    t.index ["ggv_uuid"], name: "index_gogovan_orders_on_ggv_uuid", unique: true
  end

  create_table "gogovan_transports", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "disabled", default: false
  end

  create_table "goodcity_requests", id: :serial, force: :cascade do |t|
    t.integer "quantity"
    t.integer "package_type_id"
    t.integer "order_id"
    t.text "description"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_goodcity_requests_on_created_by_id"
    t.index ["order_id"], name: "index_goodcity_requests_on_order_id"
    t.index ["package_type_id"], name: "index_goodcity_requests_on_package_type_id"
  end

  create_table "goodcity_settings", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.string "description"
    t.index ["key"], name: "index_goodcity_settings_on_key"
  end

  create_table "holidays", id: :serial, force: :cascade do |t|
    t.datetime "holiday"
    t.integer "year"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "identity_types", id: :serial, force: :cascade do |t|
    t.string "identifier"
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.string "cloudinary_id"
    t.boolean "favourite", default: false
    t.integer "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "angle", default: 0
    t.integer "imageable_id"
    t.string "imageable_type"
    t.index ["imageable_id", "imageable_type"], name: "index_images_on_imageable_id_and_imageable_type"
  end

  create_table "inventory_numbers", id: :serial, force: :cascade do |t|
    t.string "code"
  end

  create_table "items", id: :serial, force: :cascade do |t|
    t.text "donor_description"
    t.string "state"
    t.integer "offer_id", null: false
    t.integer "package_type_id"
    t.integer "rejection_reason_id"
    t.string "reject_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "donor_condition_id"
    t.datetime "deleted_at"
    t.text "rejection_comments"
    t.index ["donor_condition_id"], name: "index_items_on_donor_condition_id"
    t.index ["offer_id"], name: "index_items_on_offer_id"
    t.index ["package_type_id"], name: "index_items_on_package_type_id"
    t.index ["rejection_reason_id"], name: "index_items_on_rejection_reason_id"
  end

  create_table "locations", id: :serial, force: :cascade do |t|
    t.string "building"
    t.string "area"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area"], name: "index_locations_on_area", using: :gin
    t.index ["building"], name: "index_locations_on_building", using: :gin
  end

  create_table "lookups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "key"
    t.string "label_en"
    t.string "label_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "label_en"], name: "index_lookups_on_name_and_label_en"
    t.index ["name", "label_zh_tw"], name: "index_lookups_on_name_and_label_zh_tw"
    t.index ["name"], name: "index_lookups_on_name"
  end

  create_table "medicals", id: :serial, force: :cascade do |t|
    t.string "serial_number"
    t.string "model"
    t.string "brand"
    t.integer "country_id"
    t.integer "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.text "body"
    t.integer "sender_id"
    t.boolean "is_private", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "messageable_type"
    t.integer "messageable_id"
    t.jsonb "lookup", default: {}
    t.integer "recipient_id"
    t.index ["body"], name: "messages_body_search_idx", using: :gin
    t.index ["lookup"], name: "index_messages_on_lookup", using: :gin
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "offer_responses", force: :cascade do |t|
    t.integer "user_id"
    t.integer "offer_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id", "offer_id"], name: "index_offer_responses_on_user_id_and_offer_id", unique: true
  end

  create_table "offers", id: :serial, force: :cascade do |t|
    t.string "language"
    t.string "state"
    t.string "origin"
    t.boolean "stairs"
    t.boolean "parking"
    t.string "estimated_size"
    t.text "notes"
    t.integer "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.datetime "submitted_at"
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.integer "gogovan_transport_id"
    t.integer "crossroads_transport_id"
    t.datetime "review_completed_at"
    t.datetime "received_at"
    t.string "delivered_by", limit: 30
    t.integer "closed_by_id"
    t.datetime "cancelled_at"
    t.integer "received_by_id"
    t.datetime "start_receiving_at"
    t.integer "cancellation_reason_id"
    t.string "cancel_reason"
    t.datetime "inactive_at"
    t.boolean "saleable", default: false
    t.integer "company_id"
    t.index ["cancellation_reason_id"], name: "index_offers_on_cancellation_reason_id"
    t.index ["closed_by_id"], name: "index_offers_on_closed_by_id"
    t.index ["company_id"], name: "index_offers_on_company_id"
    t.index ["created_by_id"], name: "index_offers_on_created_by_id"
    t.index ["crossroads_transport_id"], name: "index_offers_on_crossroads_transport_id"
    t.index ["gogovan_transport_id"], name: "index_offers_on_gogovan_transport_id"
    t.index ["notes"], name: "offers_notes_search_idx", using: :gin
    t.index ["received_by_id"], name: "index_offers_on_received_by_id"
    t.index ["reviewed_by_id"], name: "index_offers_on_reviewed_by_id"
    t.index ["state"], name: "index_offers_on_state"
  end

  create_table "offers_packages", id: :serial, force: :cascade do |t|
    t.integer "package_id"
    t.integer "offer_id"
  end

  create_table "order_transports", id: :serial, force: :cascade do |t|
    t.datetime "scheduled_at"
    t.string "timeslot"
    t.string "transport_type"
    t.integer "contact_id"
    t.integer "gogovan_order_id"
    t.integer "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "need_english", default: false
    t.boolean "need_cart", default: false
    t.boolean "need_carry", default: false
    t.boolean "need_over_6ft", default: false
    t.integer "gogovan_transport_id"
    t.string "remove_net"
    t.index ["contact_id"], name: "index_order_transports_on_contact_id"
    t.index ["gogovan_order_id"], name: "index_order_transports_on_gogovan_order_id"
    t.index ["gogovan_transport_id"], name: "index_order_transports_on_gogovan_transport_id"
    t.index ["order_id"], name: "index_order_transports_on_order_id", unique: true
    t.index ["scheduled_at"], name: "index_order_transports_on_scheduled_at"
  end

  create_table "orders", id: :serial, force: :cascade do |t|
    t.string "code"
    t.string "detail_type"
    t.integer "detail_id"
    t.datetime "created_at"
    t.datetime "updated_at", null: false
    t.text "description"
    t.integer "country_id"
    t.integer "created_by_id"
    t.integer "processed_by_id"
    t.integer "organisation_id"
    t.string "state"
    t.text "purpose_description"
    t.datetime "processed_at"
    t.integer "process_completed_by_id"
    t.datetime "process_completed_at"
    t.datetime "cancelled_at"
    t.integer "cancelled_by_id"
    t.datetime "closed_at"
    t.integer "closed_by_id"
    t.datetime "dispatch_started_at"
    t.integer "dispatch_started_by_id"
    t.integer "submitted_by_id"
    t.datetime "submitted_at"
    t.integer "people_helped", default: 0
    t.integer "beneficiary_id"
    t.integer "address_id"
    t.integer "district_id"
    t.text "cancel_reason"
    t.integer "booking_type_id"
    t.string "staff_note", default: ""
    t.integer "cancellation_reason_id"
    t.boolean "continuous", default: false
    t.date "shipment_date"
    t.integer "stockit_activity_id"
    t.integer "stockit_organisation_id"
    t.integer "stockit_contact_id"
    t.index ["address_id"], name: "index_orders_on_address_id"
    t.index ["beneficiary_id"], name: "index_orders_on_beneficiary_id"
    t.index ["cancelled_by_id"], name: "index_orders_on_cancelled_by_id"
    t.index ["closed_by_id"], name: "index_orders_on_closed_by_id"
    t.index ["code"], name: "orders_code_idx", using: :gin
    t.index ["country_id"], name: "index_orders_on_country_id"
    t.index ["created_by_id"], name: "index_orders_on_created_by_id"
    t.index ["detail_id", "detail_type"], name: "index_orders_on_detail_id_and_detail_type"
    t.index ["detail_id"], name: "index_orders_on_detail_id"
    t.index ["dispatch_started_by_id"], name: "index_orders_on_dispatch_started_by_id"
    t.index ["organisation_id"], name: "index_orders_on_organisation_id"
    t.index ["process_completed_by_id"], name: "index_orders_on_process_completed_by_id"
    t.index ["processed_by_id"], name: "index_orders_on_processed_by_id"
    t.index ["shipment_date"], name: "index_orders_on_shipment_date"
    t.index ["state"], name: "index_orders_on_state"
    t.index ["submitted_by_id"], name: "index_orders_on_submitted_by_id"
  end

  create_table "orders_packages", id: :serial, force: :cascade do |t|
    t.integer "package_id"
    t.integer "order_id"
    t.string "state"
    t.integer "quantity"
    t.integer "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "sent_on"
    t.integer "dispatched_quantity", default: 0
    t.integer "shipping_number"
    t.index ["order_id", "package_id"], name: "index_orders_packages_on_order_id_and_package_id"
    t.index ["order_id"], name: "index_orders_packages_on_order_id"
    t.index ["package_id", "order_id"], name: "index_orders_packages_on_package_id_and_order_id"
    t.index ["package_id"], name: "index_orders_packages_on_package_id"
    t.index ["updated_by_id"], name: "index_orders_packages_on_updated_by_id"
  end

  create_table "orders_process_checklists", id: :serial, force: :cascade do |t|
    t.integer "order_id"
    t.integer "process_checklist_id"
    t.index ["order_id"], name: "index_orders_process_checklists_on_order_id"
    t.index ["process_checklist_id"], name: "index_orders_process_checklists_on_process_checklist_id"
  end

  create_table "orders_purposes", id: :serial, force: :cascade do |t|
    t.integer "order_id"
    t.integer "purpose_id"
    t.index ["order_id"], name: "index_orders_purposes_on_order_id"
    t.index ["purpose_id"], name: "index_orders_purposes_on_purpose_id"
  end

  create_table "organisation_types", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.string "category_en"
    t.string "category_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organisations", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.integer "organisation_type_id"
    t.text "description_en"
    t.text "description_zh_tw"
    t.string "registration"
    t.string "website"
    t.integer "country_id"
    t.integer "district_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "gih3_id"
    t.index ["country_id"], name: "index_organisations_on_country_id"
    t.index ["district_id"], name: "index_organisations_on_district_id"
    t.index ["name_en"], name: "index_organisations_on_name_en"
    t.index ["name_zh_tw"], name: "index_organisations_on_name_zh_tw"
    t.index ["organisation_type_id"], name: "index_organisations_on_organisation_type_id"
  end

  create_table "organisations_users", id: :serial, force: :cascade do |t|
    t.integer "organisation_id"
    t.integer "user_id"
    t.string "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "preferred_contact_number"
    t.string "status", default: "pending"
    t.index ["organisation_id"], name: "index_organisations_users_on_organisation_id"
    t.index ["user_id"], name: "index_organisations_users_on_user_id"
  end

  create_table "package_categories", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_package_categories_on_parent_id"
  end

  create_table "package_categories_package_types", id: :serial, force: :cascade do |t|
    t.integer "package_type_id"
    t.integer "package_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_category_id"], name: "index_package_categories_package_types_on_package_category_id"
    t.index ["package_type_id"], name: "index_package_categories_package_types_on_package_type_id"
  end

  create_table "package_sets", id: :serial, force: :cascade do |t|
    t.integer "package_type_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_type_id"], name: "index_package_sets_on_package_type_id"
  end

  create_table "package_types", id: :serial, force: :cascade do |t|
    t.string "code"
    t.string "name_en"
    t.string "name_zh_tw"
    t.string "other_terms_en"
    t.string "other_terms_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible_in_selects", default: false
    t.integer "location_id"
    t.boolean "allow_requests", default: true
    t.boolean "allow_package", default: false
    t.boolean "allow_pieces", default: false
    t.string "subform"
    t.boolean "allow_box", default: false
    t.boolean "allow_pallet", default: false
    t.boolean "allow_expiry_date", default: false
    t.decimal "default_value_hk_dollar"
    t.integer "length"
    t.integer "width"
    t.integer "height"
    t.string "department"
    t.text "description_en"
    t.text "description_zh_tw"
    t.index ["allow_requests"], name: "index_package_types_on_allow_requests"
    t.index ["location_id"], name: "index_package_types_on_location_id"
    t.index ["name_en"], name: "package_types_name_en_search_idx", using: :gin
    t.index ["name_zh_tw"], name: "package_types_name_zh_tw_search_idx", using: :gin
    t.index ["visible_in_selects"], name: "index_package_types_on_visible_in_selects"
  end

  create_table "packages", id: :serial, force: :cascade do |t|
    t.integer "length"
    t.integer "width"
    t.integer "height"
    t.text "notes", null: false
    t.integer "item_id"
    t.string "state"
    t.datetime "received_at"
    t.datetime "rejected_at"
    t.integer "package_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "offer_id", default: 0
    t.string "inventory_number"
    t.integer "location_id"
    t.string "designation_name"
    t.integer "donor_condition_id"
    t.string "grade"
    t.integer "box_id"
    t.integer "pallet_id"
    t.integer "order_id"
    t.integer "on_hand_boxed_quantity", default: 0
    t.integer "on_hand_palletized_quantity", default: 0
    t.integer "favourite_image_id"
    t.boolean "saleable"
    t.string "case_number"
    t.boolean "allow_web_publish"
    t.integer "received_quantity"
    t.integer "weight"
    t.integer "pieces"
    t.integer "detail_id"
    t.string "detail_type"
    t.integer "storage_type_id"
    t.integer "available_quantity", default: 0
    t.integer "on_hand_quantity", default: 0
    t.integer "designated_quantity", default: 0
    t.integer "dispatched_quantity", default: 0
    t.date "expiry_date"
    t.decimal "value_hk_dollar", null: false
    t.integer "package_set_id"
    t.integer "restriction_id"
    t.text "comment"
    t.integer "stockit_moved_by_id"
    t.datetime "stockit_moved_on"
    t.integer "stockit_sent_by_id"
    t.integer "stockit_designated_by_id"
    t.datetime "stockit_designated_on"
    t.datetime "stockit_sent_on"
    t.text "notes_zh_tw"
    t.index ["allow_web_publish"], name: "index_packages_on_allow_web_publish"
    t.index ["available_quantity"], name: "index_packages_on_available_quantity"
    t.index ["box_id"], name: "index_packages_on_box_id"
    t.index ["case_number"], name: "index_packages_on_case_number", using: :gin
    t.index ["designated_quantity"], name: "index_packages_on_designated_quantity"
    t.index ["designation_name"], name: "index_packages_on_designation_name", using: :gin
    t.index ["detail_type", "detail_id"], name: "index_packages_on_detail_type_and_detail_id"
    t.index ["dispatched_quantity"], name: "index_packages_on_dispatched_quantity"
    t.index ["donor_condition_id"], name: "index_packages_on_donor_condition_id"
    t.index ["inventory_number"], name: "index_packages_on_inventory_number"
    t.index ["inventory_number"], name: "inventory_numbers_search_idx", using: :gin
    t.index ["item_id"], name: "index_packages_on_item_id"
    t.index ["location_id"], name: "index_packages_on_location_id"
    t.index ["notes"], name: "index_packages_on_notes", using: :gin
    t.index ["offer_id"], name: "index_packages_on_offer_id"
    t.index ["on_hand_quantity"], name: "index_packages_on_on_hand_quantity"
    t.index ["order_id"], name: "index_packages_on_order_id"
    t.index ["package_set_id"], name: "index_packages_on_package_set_id"
    t.index ["package_type_id"], name: "index_packages_on_package_type_id"
    t.index ["pallet_id"], name: "index_packages_on_pallet_id"
    t.index ["state"], name: "index_packages_on_state", using: :gin
    t.index ["storage_type_id"], name: "index_packages_on_storage_type_id"
  end

  create_table "packages_inventories", id: :serial, force: :cascade do |t|
    t.integer "package_id", null: false
    t.integer "location_id", null: false
    t.integer "user_id", null: false
    t.string "action", null: false
    t.string "source_type"
    t.integer "source_id"
    t.integer "quantity", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.index ["action"], name: "index_packages_inventories_on_action"
    t.index ["created_at"], name: "index_packages_inventories_on_created_at"
    t.index ["location_id"], name: "index_packages_inventories_on_location_id"
    t.index ["package_id", "source_type"], name: "index_packages_inventories_on_package_id_and_source_type"
    t.index ["package_id"], name: "index_packages_inventories_on_package_id"
    t.index ["source_id", "source_type"], name: "index_packages_inventories_on_source_id_and_source_type"
    t.index ["source_id"], name: "index_packages_inventories_on_source_id"
    t.index ["source_type", "package_id"], name: "index_packages_inventories_on_source_type_and_package_id"
    t.index ["source_type", "source_id"], name: "index_packages_inventories_on_source_type_and_source_id"
    t.index ["source_type"], name: "index_packages_inventories_on_source_type"
    t.index ["user_id"], name: "index_packages_inventories_on_user_id"
  end

  create_table "packages_locations", id: :serial, force: :cascade do |t|
    t.integer "package_id"
    t.integer "location_id"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reference_to_orders_package"
    t.index ["location_id", "package_id"], name: "index_packages_locations_on_location_id_and_package_id"
    t.index ["location_id"], name: "index_packages_locations_on_location_id"
    t.index ["package_id", "location_id"], name: "index_packages_locations_on_package_id_and_location_id"
    t.index ["package_id"], name: "index_packages_locations_on_package_id"
    t.index ["reference_to_orders_package"], name: "index_packages_locations_on_reference_to_orders_package"
  end

  create_table "pallets", id: :serial, force: :cascade do |t|
    t.string "pallet_number"
    t.string "description"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "printers", id: :serial, force: :cascade do |t|
    t.boolean "active"
    t.integer "location_id"
    t.string "name"
    t.string "host"
    t.string "port"
    t.string "username"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "printers_users", id: :serial, force: :cascade do |t|
    t.integer "printer_id"
    t.integer "user_id"
    t.string "tag"
  end

  create_table "process_checklists", id: :serial, force: :cascade do |t|
    t.string "text_en"
    t.string "text_zh_tw"
    t.integer "booking_type_id"
    t.index ["booking_type_id"], name: "index_process_checklists_on_booking_type_id"
  end

  create_table "processing_destinations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "purposes", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
  end

  create_table "rejection_reasons", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name_zh_tw"
  end

  create_table "requested_packages", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "package_id"
    t.boolean "is_available"
    t.integer "quantity", default: 1
    t.index ["package_id", "user_id"], name: "index_requested_packages_on_package_id_and_user_id", unique: true
    t.index ["package_id"], name: "index_requested_packages_on_package_id"
    t.index ["user_id", "package_id"], name: "index_requested_packages_on_user_id_and_package_id", unique: true
    t.index ["user_id"], name: "index_requested_packages_on_user_id"
  end

  create_table "restrictions", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "role_permissions", id: :serial, force: :cascade do |t|
    t.integer "role_id"
    t.integer "permission_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "level"
    t.index ["level"], name: "index_roles_on_level"
  end

  create_table "schedules", id: :serial, force: :cascade do |t|
    t.string "resource"
    t.integer "slot"
    t.string "slot_name"
    t.string "zone"
    t.datetime "scheduled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shareables", force: :cascade do |t|
    t.string "resource_type", null: false
    t.integer "resource_id", null: false
    t.string "public_uid", null: false
    t.boolean "allow_listing", default: false, null: false
    t.datetime "expires_at"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.text "notes_zh_tw"
    t.index ["created_by_id"], name: "index_shareables_on_created_by_id"
    t.index ["expires_at"], name: "index_shareables_on_expires_at"
    t.index ["public_uid"], name: "index_shareables_on_public_uid"
    t.index ["resource_id", "resource_type"], name: "index_shareables_on_resource_id_and_resource_type", unique: true
    t.index ["resource_type", "resource_id"], name: "index_shareables_on_resource_type_and_resource_id", unique: true
    t.index ["resource_type"], name: "index_shareables_on_resource_type"
  end

  create_table "stockit_activities", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stockit_contacts", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "mobile_phone_number"
    t.string "phone_number"
    t.integer "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["first_name"], name: "st_contacts_first_name_idx", using: :gin
    t.index ["last_name"], name: "st_contacts_last_name_idx", using: :gin
    t.index ["mobile_phone_number"], name: "st_contacts_mobile_phone_number_idx", using: :gin
    t.index ["phone_number"], name: "st_contacts_phone_number_idx", using: :gin
  end

  create_table "stockit_local_orders", id: :serial, force: :cascade do |t|
    t.string "client_name"
    t.string "hkid_number"
    t.string "reference_number"
    t.integer "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "purpose_of_goods"
    t.index ["client_name"], name: "st_local_orders_client_name_idx", using: :gin
  end

  create_table "stockit_organisations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "stockit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "st_organisations_name_idx", using: :gin
  end

  create_table "stocktake_revisions", id: :serial, force: :cascade do |t|
    t.integer "stocktake_id", null: false
    t.integer "package_id", null: false
    t.integer "quantity", default: 0, null: false
    t.string "state", default: "pending", null: false
    t.boolean "dirty", default: false, null: false
    t.string "warning"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "processed_delta", default: 0
    t.index ["package_id", "stocktake_id"], name: "index_stocktake_revisions_on_package_id_and_stocktake_id", unique: true
    t.index ["package_id"], name: "index_stocktake_revisions_on_package_id"
    t.index ["stocktake_id", "package_id"], name: "index_stocktake_revisions_on_stocktake_id_and_package_id", unique: true
    t.index ["stocktake_id"], name: "index_stocktake_revisions_on_stocktake_id"
  end

  create_table "stocktakes", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "state", default: "open"
    t.string "comment"
    t.integer "created_by_id"
    t.integer "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "counts", default: 0
    t.integer "gains", default: 0
    t.integer "losses", default: 0
    t.integer "warnings", default: 0
    t.index ["location_id"], name: "index_stocktakes_on_location_id"
    t.index ["name"], name: "index_stocktakes_on_name", unique: true
  end

  create_table "storage_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_unit_quantity"
  end

  create_table "stripe_payments", force: :cascade do |t|
    t.integer "user_id"
    t.string "setup_intent_id"
    t.string "payment_method_id"
    t.string "payment_intent_id"
    t.float "amount"
    t.string "status"
    t.string "receipt_url"
    t.string "source_type"
    t.integer "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subpackage_types", id: :serial, force: :cascade do |t|
    t.integer "package_type_id"
    t.integer "subpackage_type_id"
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_type_id"], name: "index_subpackage_types_on_package_type_id"
    t.index ["package_type_id"], name: "index_subpackage_types_on_package_type_id_and_package_type_id"
    t.index ["subpackage_type_id"], name: "index_subpackage_types_on_subpackage_type_id"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "message_id"
    t.string "state"
    t.string "subscribable_type"
    t.integer "subscribable_id"
    t.index ["message_id"], name: "index_subscriptions_on_message_id"
    t.index ["state"], name: "index_subscriptions_on_state"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "territories", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timeslots", id: :serial, force: :cascade do |t|
    t.string "name_en"
    t.string "name_zh_tw"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transport_orders", force: :cascade do |t|
    t.integer "transport_provider_id"
    t.string "order_uuid"
    t.string "status"
    t.datetime "scheduled_at"
    t.jsonb "metadata"
    t.integer "source_id"
    t.string "source_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transport_providers", force: :cascade do |t|
    t.string "name"
    t.string "logo"
    t.text "description"
    t.jsonb "metadata", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_favourites", force: :cascade do |t|
    t.string "favourite_type"
    t.integer "favourite_id"
    t.integer "user_id"
    t.boolean "persistent", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["favourite_type"], name: "index_user_favourites_on_favourite_type"
    t.index ["updated_at"], name: "index_user_favourites_on_updated_at"
    t.index ["user_id", "favourite_type", "favourite_id"], name: "index_user_and_favourites", unique: true
  end

  create_table "user_roles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "image_id"
    t.datetime "last_connected"
    t.datetime "last_disconnected"
    t.boolean "disabled", default: false
    t.string "email"
    t.string "title"
    t.datetime "sms_reminder_sent_at"
    t.boolean "is_mobile_verified", default: false
    t.boolean "is_email_verified", default: false
    t.boolean "receive_email", default: false
    t.string "other_phone"
    t.string "preferred_language"
    t.string "stripe_customer_id"
    t.index ["image_id"], name: "index_users_on_image_id"
    t.index ["mobile"], name: "index_users_on_mobile"
    t.index ["sms_reminder_sent_at"], name: "index_users_on_sms_reminder_sent_at"
  end

  create_table "valuation_matrices", id: :serial, force: :cascade do |t|
    t.integer "donor_condition_id", null: false
    t.string "grade", null: false
    t.decimal "multiplier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.integer "related_id"
    t.string "related_type"
    t.datetime "created_at"
    t.index ["created_at", "whodunnit"], name: "partial_index_recent_locations", where: "(((event)::text = ANY (ARRAY[('create'::character varying)::text, ('update'::character varying)::text])) AND (object_changes ? 'location_id'::text))"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["event"], name: "index_versions_on_event"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["item_type"], name: "index_versions_on_item_type"
    t.index ["related_type", "related_id"], name: "index_versions_on_related_type_and_related_id"
    t.index ["related_type"], name: "index_versions_on_related_type"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  add_foreign_key "access_pass_roles", "access_passes"
  add_foreign_key "access_pass_roles", "roles"
  add_foreign_key "access_passes", "printers"
  add_foreign_key "addresses", "districts", name: "addresses_district_id_fk"
  add_foreign_key "auth_tokens", "users", name: "auth_tokens_user_id_fk"
  add_foreign_key "beneficiaries", "identity_types"
  add_foreign_key "beneficiaries", "users", column: "created_by_id", name: "beneficiaries_created_by_id_fk"
  add_foreign_key "boxes", "pallets", name: "boxes_pallet_id_fk"
  add_foreign_key "computer_accessories", "countries", name: "computer_accessories_country_id_fk"
  add_foreign_key "computer_accessories", "lookups", column: "comp_test_status_id", name: "computer_accessories_comp_test_status_id_fk"
  add_foreign_key "computers", "countries", name: "computers_country_id_fk"
  add_foreign_key "computers", "lookups", column: "comp_test_status_id", name: "computers_comp_test_status_id_fk"
  add_foreign_key "deliveries", "contacts", name: "deliveries_contact_id_fk"
  add_foreign_key "deliveries", "gogovan_orders", name: "deliveries_gogovan_order_id_fk"
  add_foreign_key "deliveries", "offers", name: "deliveries_offer_id_fk"
  add_foreign_key "deliveries", "schedules", name: "deliveries_schedule_id_fk"
  add_foreign_key "districts", "territories", name: "districts_territory_id_fk"
  add_foreign_key "electricals", "countries", name: "electricals_country_id_fk"
  add_foreign_key "electricals", "lookups", column: "frequency_id", name: "electricals_frequency_id_fk"
  add_foreign_key "electricals", "lookups", column: "test_status_id", name: "electricals_test_status_id_fk"
  add_foreign_key "electricals", "lookups", column: "voltage_id", name: "electricals_voltage_id_fk"
  add_foreign_key "goodcity_requests", "orders"
  add_foreign_key "goodcity_requests", "package_types"
  add_foreign_key "goodcity_requests", "users", column: "created_by_id", name: "goodcity_requests_created_by_id_fk"
  add_foreign_key "items", "donor_conditions", name: "items_donor_condition_id_fk"
  add_foreign_key "items", "offers", name: "items_offer_id_fk"
  add_foreign_key "items", "package_types", name: "items_package_type_id_fk"
  add_foreign_key "items", "rejection_reasons", name: "items_rejection_reason_id_fk"
  add_foreign_key "medicals", "countries", name: "medicals_country_id_fk"
  add_foreign_key "messages", "users", column: "recipient_id"
  add_foreign_key "messages", "users", column: "sender_id", name: "messages_sender_id_fk"
  add_foreign_key "offer_responses", "offers"
  add_foreign_key "offer_responses", "users"
  add_foreign_key "offers", "cancellation_reasons", name: "offers_cancellation_reason_id_fk"
  add_foreign_key "offers", "companies", name: "offers_company_id_fk"
  add_foreign_key "offers", "crossroads_transports", name: "offers_crossroads_transport_id_fk"
  add_foreign_key "offers", "gogovan_transports", name: "offers_gogovan_transport_id_fk"
  add_foreign_key "offers", "users", column: "closed_by_id", name: "offers_closed_by_id_fk"
  add_foreign_key "offers", "users", column: "created_by_id", name: "offers_created_by_id_fk"
  add_foreign_key "offers", "users", column: "received_by_id", name: "offers_received_by_id_fk"
  add_foreign_key "offers", "users", column: "reviewed_by_id", name: "offers_reviewed_by_id_fk"
  add_foreign_key "offers_packages", "offers"
  add_foreign_key "offers_packages", "packages"
  add_foreign_key "order_transports", "contacts", name: "order_transports_contact_id_fk"
  add_foreign_key "order_transports", "gogovan_orders", name: "order_transports_gogovan_order_id_fk"
  add_foreign_key "order_transports", "gogovan_transports", name: "order_transports_gogovan_transport_id_fk"
  add_foreign_key "order_transports", "orders", name: "order_transports_order_id_fk"
  add_foreign_key "orders", "addresses", name: "orders_address_id_fk"
  add_foreign_key "orders", "beneficiaries", name: "orders_beneficiary_id_fk"
  add_foreign_key "orders", "booking_types", name: "orders_booking_type_id_fk"
  add_foreign_key "orders", "cancellation_reasons", name: "orders_cancellation_reason_id_fk"
  add_foreign_key "orders", "countries", name: "orders_country_id_fk"
  add_foreign_key "orders", "districts", name: "orders_district_id_fk"
  add_foreign_key "orders", "organisations", name: "orders_organisation_id_fk"
  add_foreign_key "orders", "stockit_local_orders", column: "detail_id", name: "orders_detail_id_fk"
  add_foreign_key "orders", "users", column: "cancelled_by_id", name: "orders_cancelled_by_id_fk"
  add_foreign_key "orders", "users", column: "closed_by_id", name: "orders_closed_by_id_fk"
  add_foreign_key "orders", "users", column: "created_by_id", name: "orders_created_by_id_fk"
  add_foreign_key "orders", "users", column: "dispatch_started_by_id", name: "orders_dispatch_started_by_id_fk"
  add_foreign_key "orders", "users", column: "process_completed_by_id", name: "orders_process_completed_by_id_fk"
  add_foreign_key "orders", "users", column: "processed_by_id", name: "orders_processed_by_id_fk"
  add_foreign_key "orders", "users", column: "submitted_by_id", name: "orders_submitted_by_id_fk"
  add_foreign_key "orders_packages", "orders", name: "orders_packages_order_id_fk"
  add_foreign_key "orders_packages", "packages", name: "orders_packages_package_id_fk"
  add_foreign_key "orders_packages", "users", column: "updated_by_id", name: "orders_packages_updated_by_id_fk"
  add_foreign_key "orders_process_checklists", "orders"
  add_foreign_key "orders_process_checklists", "process_checklists"
  add_foreign_key "orders_purposes", "orders", name: "orders_purposes_order_id_fk"
  add_foreign_key "orders_purposes", "purposes", name: "orders_purposes_purpose_id_fk"
  add_foreign_key "organisations", "countries"
  add_foreign_key "organisations", "districts"
  add_foreign_key "organisations", "organisation_types"
  add_foreign_key "organisations_users", "organisations"
  add_foreign_key "organisations_users", "users"
  add_foreign_key "package_categories", "package_categories", column: "parent_id", name: "package_categories_parent_id_fk"
  add_foreign_key "package_categories_package_types", "package_categories", name: "package_categories_package_types_package_category_id_fk"
  add_foreign_key "package_categories_package_types", "package_types", name: "package_categories_package_types_package_type_id_fk"
  add_foreign_key "package_sets", "package_types", name: "package_sets_package_type_id_fk"
  add_foreign_key "package_types", "locations", name: "package_types_location_id_fk"
  add_foreign_key "packages", "boxes", name: "packages_box_id_fk"
  add_foreign_key "packages", "donor_conditions", name: "packages_donor_condition_id_fk"
  add_foreign_key "packages", "items", name: "packages_item_id_fk"
  add_foreign_key "packages", "orders", name: "packages_order_id_fk"
  add_foreign_key "packages", "package_sets", name: "packages_package_set_id_fk"
  add_foreign_key "packages", "package_types", name: "packages_package_type_id_fk"
  add_foreign_key "packages", "pallets", name: "packages_pallet_id_fk"
  add_foreign_key "packages", "restrictions", name: "packages_restriction_id_fk"
  add_foreign_key "packages", "storage_types", name: "packages_storage_type_id_fk"
  add_foreign_key "packages_inventories", "locations"
  add_foreign_key "packages_inventories", "packages"
  add_foreign_key "packages_inventories", "users"
  add_foreign_key "packages_locations", "locations", name: "packages_locations_location_id_fk"
  add_foreign_key "packages_locations", "packages", name: "packages_locations_package_id_fk"
  add_foreign_key "printers", "locations", name: "printers_location_id_fk"
  add_foreign_key "process_checklists", "booking_types"
  add_foreign_key "requested_packages", "packages", name: "requested_packages_package_id_fk"
  add_foreign_key "requested_packages", "users", name: "requested_packages_user_id_fk"
  add_foreign_key "role_permissions", "permissions", name: "role_permissions_permission_id_fk"
  add_foreign_key "role_permissions", "roles", name: "role_permissions_role_id_fk"
  add_foreign_key "stocktake_revisions", "packages"
  add_foreign_key "stocktake_revisions", "stocktakes"
  add_foreign_key "stocktake_revisions", "users", column: "created_by_id", name: "stocktake_revisions_created_by_id_fk"
  add_foreign_key "stocktakes", "locations"
  add_foreign_key "stocktakes", "users", column: "created_by_id", name: "stocktakes_created_by_id_fk"
  add_foreign_key "subpackage_types", "package_types", column: "subpackage_type_id", name: "subpackage_types_subpackage_type_id_fk"
  add_foreign_key "subpackage_types", "package_types", name: "subpackage_types_package_type_id_fk"
  add_foreign_key "subscriptions", "messages", name: "subscriptions_message_id_fk"
  add_foreign_key "subscriptions", "users", name: "subscriptions_user_id_fk"
  add_foreign_key "user_favourites", "users"
  add_foreign_key "user_roles", "roles", name: "user_roles_role_id_fk"
  add_foreign_key "user_roles", "users", name: "user_roles_user_id_fk"
  add_foreign_key "users", "images", name: "users_image_id_fk"
  add_foreign_key "valuation_matrices", "donor_conditions"
end
