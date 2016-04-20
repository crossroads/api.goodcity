# This file is auto-generated from the current state of the database. Instead of editing this file,
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160108132515) do

  create_table "activities", :force => true do |t|
    t.string "name"
  end

  create_table "boxes", :force => true do |t|
    t.string   "box_number",  :limit => 10
    t.integer  "pallet_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.text     "comments"
  end

  create_table "carry_outs", :force => true do |t|
    t.string "staff_name"
  end

  create_table "code_valuations", :force => true do |t|
    t.integer "code_id"
    t.string  "condition", :limit => 1
    t.string  "grade",     :limit => 1
    t.decimal "value",                  :precision => 10, :scale => 2
  end

  create_table "codes", :force => true do |t|
    t.string   "code",                     :limit => 5
    t.string   "description_en"
    t.string   "description_format"
    t.string   "description_default"
    t.string   "subform"
    t.string   "unit_type"
    t.string   "rrp_low_shop",             :limit => 50
    t.string   "rrp_high_shop",            :limit => 50
    t.string   "rrp_low_product",          :limit => 50
    t.string   "rrp_high_product",         :limit => 50
    t.decimal  "rrp_low_value",                          :precision => 10, :scale => 2
    t.decimal  "rrp_high_value",                         :precision => 10, :scale => 2
    t.integer  "department_id"
    t.integer  "default_length"
    t.integer  "default_width"
    t.integer  "default_height"
    t.integer  "default_weight"
    t.integer  "customs_value"
    t.string   "invoice_category"
    t.string   "status",                                                                :default => "Active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "location_id"
    t.integer  "processing_department_id"
    t.boolean  "allow_donations",                                                       :default => false
    t.boolean  "allow_requests",                                                        :default => false
    t.decimal  "high_stock_level"
    t.decimal  "low_stock_level"
    t.string   "description_ru"
    t.string   "description_zh"
    t.string   "instructions_donate_en"
    t.string   "instructions_donate_ru"
    t.string   "instructions_donate_zh"
    t.string   "instructions_request_en"
    t.string   "instructions_request_ru"
    t.string   "instructions_request_zh"
    t.string   "description_zht"
    t.string   "instructions_donate_zht"
    t.string   "instructions_request_zht"
  end

  add_index "codes", ["department_id"], :name => "index_codes_on_department_id"
  add_index "codes", ["location_id"], :name => "index_codes_on_location_id"
  add_index "codes", ["processing_department_id"], :name => "index_codes_on_processing_department_id"

  create_table "computer_accessories", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "brand",            :limit => 30
    t.string   "model",            :limit => 30
    t.string   "serial_num",       :limit => 30
    t.integer  "country_id"
    t.string   "size",             :limit => 30
    t.string   "printer",          :limit => 30
    t.string   "scanner",          :limit => 30
    t.string   "interface",        :limit => 30
    t.string   "comp_voltage",     :limit => 30
    t.string   "comp_test_status", :limit => 30
  end

  create_table "computers", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "brand",                    :limit => 80
    t.string   "model",                    :limit => 80
    t.string   "serial_num",               :limit => 80
    t.integer  "country_id"
    t.string   "size",                     :limit => 80
    t.string   "cpu",                      :limit => 80
    t.string   "socket",                   :limit => 80
    t.string   "fsb",                      :limit => 80
    t.string   "ram",                      :limit => 80
    t.string   "hdd",                      :limit => 80
    t.string   "floppy",                   :limit => 80
    t.string   "zip",                      :limit => 80
    t.string   "optical",                  :limit => 80
    t.string   "video",                    :limit => 80
    t.string   "sound",                    :limit => 80
    t.string   "lan",                      :limit => 80
    t.string   "wireless",                 :limit => 80
    t.string   "modem",                    :limit => 80
    t.string   "scsi",                     :limit => 80
    t.string   "tv_tuner",                 :limit => 80
    t.string   "usb",                      :limit => 80
    t.string   "firewire",                 :limit => 80
    t.string   "interface",                :limit => 80
    t.string   "comp_voltage",             :limit => 80
    t.string   "comp_test_status",         :limit => 80
    t.string   "os",                       :limit => 80
    t.string   "os_serial_num",            :limit => 80
    t.string   "ms_office_serial_num",     :limit => 80
    t.string   "mar_os_serial_num"
    t.string   "mar_ms_office_serial_num"
  end

  create_table "contacts", :force => true do |t|
    t.string   "title"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "position"
    t.string   "address_building"
    t.string   "address_street"
    t.string   "address_suburb"
    t.string   "phone_number"
    t.string   "mobile_phone_number"
    t.string   "alternative_phone_number"
    t.string   "email"
    t.string   "fax_number"
    t.string   "preferred_communication_method"
    t.text     "notes"
    t.string   "updated_by"
    t.integer  "organisation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "archived",                       :default => false
    t.integer  "country_id"
  end

  create_table "container_types", :force => true do |t|
    t.string   "name"
    t.integer  "cbm_all_cartons"
    t.integer  "cbm_mixed_stock"
    t.integer  "cbm_picklist_max"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "countries", :force => true do |t|
    t.string   "code"
    t.string   "name_en"
    t.string   "name_ru"
    t.string   "name_zh"
    t.string   "region_en"
    t.string   "region_ru"
    t.string   "region_zh"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "departments", :force => true do |t|
    t.string  "name_en",                 :limit => 50
    t.string  "name_ru",                 :limit => 50
    t.string  "name_zh",                 :limit => 50
    t.string  "inventory_number_prefix", :limit => 1
    t.integer "next_inventory_number",                 :default => 0
    t.boolean "allow_multiple_packages",               :default => false
    t.boolean "allow_pallets",                         :default => true
    t.boolean "allow_boxes",                           :default => true
    t.boolean "allow_packages",                        :default => true
    t.string  "name_zht",                :limit => 50
  end

  create_table "departments_people", :id => false, :force => true do |t|
    t.integer "department_id"
    t.integer "person_id"
  end

  create_table "designation_requests", :force => true do |t|
    t.integer  "quantity_requested",                                              :default => 1
    t.integer  "quantity_to_pack",                                                :default => 1
    t.decimal  "cbm_per_unit",                     :precision => 10, :scale => 3
    t.string   "comments"
    t.string   "priority",           :limit => 1,                                 :default => "A"
    t.boolean  "is_published",                                                    :default => false
    t.boolean  "is_packed",                                                       :default => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "code_id"
    t.integer  "designation_id"
    t.integer  "length"
    t.integer  "width"
    t.integer  "height"
    t.string   "item_requested"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "highlight",          :limit => 10
  end

  create_table "designations", :force => true do |t|
    t.string   "code",                    :limit => 30
    t.integer  "country_id"
    t.string   "status"
    t.string   "comments"
    t.text     "description"
    t.date     "started_on"
    t.datetime "goods_ready_at"
    t.date     "ship_ready_on"
    t.date     "loading_on"
    t.date     "sent_on"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "detail_id"
    t.string   "detail_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "contact_id"
    t.integer  "organisation_id"
    t.integer  "activity_id"
    t.integer  "remote_id"
    t.boolean  "not_reported",                          :default => false
    t.integer  "number_of_people_helped"
    t.boolean  "continuous",                            :default => false
  end

  add_index "designations", ["code"], :name => "index_designations_on_code", :unique => true
  add_index "designations", ["country_id"], :name => "index_designations_on_country_id"
  add_index "designations", ["detail_id"], :name => "index_designations_on_detail_id"
  add_index "designations", ["detail_type"], :name => "index_designations_on_detail_type"

  create_table "designations_primary_global_issues", :id => false, :force => true do |t|
    t.integer "designation_id"
    t.integer "global_issue_id"
  end

  create_table "designations_secondary_global_issues", :id => false, :force => true do |t|
    t.integer "designation_id"
    t.integer "global_issue_id"
  end

  create_table "electricals", :force => true do |t|
    t.string   "brand",            :limit => 30
    t.string   "model",            :limit => 30
    t.string   "serial_number",    :limit => 30
    t.integer  "country_id"
    t.string   "standard",         :limit => 30
    t.integer  "voltage"
    t.integer  "frequency"
    t.string   "power",            :limit => 30
    t.string   "system_or_region", :limit => 30
    t.string   "test_status",      :limit => 1
    t.date     "tested_on"
    t.string   "tested_by",        :limit => 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "global_issues", :force => true do |t|
    t.string "title"
  end

  create_table "globalize_countries", :force => true do |t|
    t.string "code",                   :limit => 2
    t.string "english_name"
    t.string "date_format"
    t.string "currency_format"
    t.string "currency_code",          :limit => 3
    t.string "thousands_sep",          :limit => 2
    t.string "decimal_sep",            :limit => 2
    t.string "currency_decimal_sep",   :limit => 2
    t.string "number_grouping_scheme"
  end

  add_index "globalize_countries", ["code"], :name => "index_globalize_countries_on_code"

  create_table "globalize_languages", :force => true do |t|
    t.string  "iso_639_1",             :limit => 2
    t.string  "iso_639_2",             :limit => 3
    t.string  "iso_639_3",             :limit => 3
    t.string  "rfc_3066"
    t.string  "english_name"
    t.string  "english_name_locale"
    t.string  "english_name_modifier"
    t.string  "native_name"
    t.string  "native_name_locale"
    t.string  "native_name_modifier"
    t.boolean "macro_language"
    t.string  "direction"
    t.string  "pluralization"
    t.string  "scope",                 :limit => 1
  end

  add_index "globalize_languages", ["iso_639_1"], :name => "index_globalize_languages_on_iso_639_1"
  add_index "globalize_languages", ["iso_639_2"], :name => "index_globalize_languages_on_iso_639_2"
  add_index "globalize_languages", ["iso_639_3"], :name => "index_globalize_languages_on_iso_639_3"
  add_index "globalize_languages", ["rfc_3066"], :name => "index_globalize_languages_on_rfc_3066"

  create_table "globalize_translations", :force => true do |t|
    t.string  "type"
    t.string  "tr_key"
    t.string  "table_name"
    t.integer "item_id"
    t.string  "facet"
    t.integer "language_id"
    t.integer "pluralization_index"
    t.text    "text"
    t.string  "namespace"
  end

  add_index "globalize_translations", ["table_name", "item_id", "language_id"], :name => "globalize_translations_table_name_and_item_and_language"
  add_index "globalize_translations", ["tr_key", "language_id"], :name => "index_globalize_translations_on_tr_key_and_language_id"

  create_table "images", :force => true do |t|
    t.integer  "parent_id"
    t.string   "content_type"
    t.string   "filename"
    t.string   "thumbnail"
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", :force => true do |t|
    t.string   "inventory_number",         :limit => 15
    t.string   "description"
    t.text     "comments"
    t.integer  "quantity",                                :default => 1
    t.boolean  "is_published",                            :default => false
    t.boolean  "is_deleted",                              :default => false
    t.decimal  "overridden_value"
    t.string   "condition"
    t.string   "grade"
    t.string   "image_path"
    t.integer  "moved_by"
    t.integer  "designated_by"
    t.integer  "sent_by"
    t.integer  "processed_by"
    t.integer  "stocktake_by"
    t.integer  "value_updated_by"
    t.date     "processed_on"
    t.date     "moved_on"
    t.date     "designated_on"
    t.date     "sent_on"
    t.date     "stocktake_on"
    t.date     "value_updated_on"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "code_id"
    t.integer  "location_id"
    t.integer  "designation_id"
    t.integer  "box_id"
    t.integer  "pallet_id"
    t.integer  "detail_id"
    t.string   "detail_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_department_id"
    t.boolean  "is_wrong_value",                          :default => false
    t.integer  "image_id"
    t.integer  "pieces"
    t.date     "pat_test_date"
    t.string   "pat_test_id",              :limit => 120
    t.string   "pat_test_status",          :limit => 100
    t.string   "pat_device_serial_number", :limit => 120
    t.string   "case_number",              :limit => 100
  end

  add_index "items", ["box_id"], :name => "index_items_on_box_id"
  add_index "items", ["code_id"], :name => "index_items_on_code_id"
  add_index "items", ["designation_id"], :name => "index_items_on_designation_id"
  add_index "items", ["detail_id"], :name => "index_items_on_detail_id"
  add_index "items", ["detail_type"], :name => "index_items_on_detail_type"
  add_index "items", ["location_id"], :name => "index_items_on_location_id"
  add_index "items", ["pallet_id"], :name => "index_items_on_pallet_id"

  create_table "local_orders", :force => true do |t|
    t.string  "staff_name"
    t.string  "client_name"
    t.string  "hkid_number",             :limit => 50
    t.date    "info_sent_on"
    t.string  "reference_number",        :limit => 20
    t.text    "purpose_of_goods"
    t.boolean "follow_up_visit"
    t.string  "follow_up_visit_comment"
    t.boolean "follow_up_story"
    t.boolean "transport_private"
    t.boolean "transport_hire"
    t.boolean "supply_own_labour"
    t.string  "collection_dates"
    t.string  "cancelled_reason",        :limit => 50
    t.text    "cancelled_comment"
  end

  create_table "locations", :force => true do |t|
    t.string   "building",   :limit => 20
    t.string   "area",       :limit => 20
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "virtual",                  :default => false
  end

  create_table "medicals", :force => true do |t|
    t.string   "brand",           :limit => 30
    t.string   "model",           :limit => 30
    t.integer  "country_id"
    t.date     "expiry_date"
    t.string   "entered_by_user", :limit => 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organisations", :force => true do |t|
    t.string   "name"
    t.string   "organisation_type"
    t.string   "website"
    t.text     "registration"
    t.text     "description"
    t.integer  "contact_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "archived",          :default => false
    t.boolean  "duplicate",         :default => false
  end

  create_table "others", :force => true do |t|
    t.string "key"
    t.string "value"
  end

  create_table "packages", :force => true do |t|
    t.integer  "item_id"
    t.integer  "box_id"
    t.string   "package_description"
    t.integer  "length"
    t.integer  "width"
    t.integer  "height"
    t.integer  "weight"
    t.integer  "shipping_number"
    t.decimal  "cbm",                 :precision => 10, :scale => 3
    t.integer  "adjusted_weight"
    t.integer  "adjusted_value"
    t.boolean  "is_loose_pack",                                      :default => false
    t.integer  "trial_run_by"
    t.date     "trial_run_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comments"
  end

  add_index "packages", ["box_id"], :name => "index_packages_on_box_id"
  add_index "packages", ["item_id"], :name => "index_packages_on_item_id"

  create_table "pallets", :force => true do |t|
    t.string   "pallet_number", :limit => 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.text     "comments"
    t.boolean  "is_deleted",                  :default => false
  end

  create_table "people", :force => true do |t|
    t.binary   "guid"
    t.string   "username",   :limit => 50
    t.string   "name",       :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people_roles", :id => false, :force => true do |t|
    t.integer  "person_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", :force => true do |t|
    t.string   "name",       :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions_roles", :id => false, :force => true do |t|
    t.integer  "role_id"
    t.integer  "permission_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name",       :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shipments", :force => true do |t|
    t.string  "shipping_mark"
    t.string  "shipping_area"
    t.string  "shipping_country"
    t.decimal "container_cbm"
    t.integer "next_shipping_number",                :default => 0
    t.string  "project_type",          :limit => 10
    t.string  "container_ownership",   :limit => 10
    t.string  "shipment_type",         :limit => 20
    t.string  "cbm_type",              :limit => 20
    t.string  "label_colour",          :limit => 6
    t.date    "picklist_drafted_on"
    t.date    "picklist_finalised_on"
    t.date    "followup_letter1_on"
    t.date    "followup_letter2_on"
    t.integer "container_type_id"
    t.string  "transport_cost"
  end

end
