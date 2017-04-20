# ChangeLog

Detailed list of changes that will affect the live system during an upgrade.

## Version 0.5

Update chinese translations for `cancellation_reasons` in https://github.com/crossroads/api.goodcity/blob/master/db/cancellation_reasons.yml

Add `cancellation_reasons`

    cancellation_reasons = YAML.load_file("#{Rails.root}/db/cancellation_reasons.yml")
    cancellation_reasons.each do |name_en, value|
      FactoryGirl.create(:cancellation_reason,
        name_en: name_en,
        name_zh_tw: value[:name_zh_tw],
        visible_to_admin: value[:visible_to_admin] )
    end

Create api-write permission

    FactoryGirl.create(:permission, name: "api-write")

Rake tasks to run:

    rake stockit:add_stockit_locations
    rake goodcity:update_cancelled_offers
    rake goodcity:update_closed_offers

Add `Stockit User`

    rake goodcity:add_stockit_user

  Copy the `token` returned from above task to `stockit/config/secrets.yml`

Add follwing environment variables in `.env` file

    STOCKIT_API_TOKEN=
    JWT_VALIDITY_FOR_API=

## Version 0.6

Rake tasks to run:

    rake goodcity:update_offers_cancelled_with_unwanted_reason
    rake goodcity:update_packages_grade_condition

## Version 0.8

Rake tasks to run:

    rake goodcity:update_timeslots
    rake goodcity:update_delivery_schedule_slotname
    rake goodcity:update_items_saleable_field

## Version 0.9

Rake tasks to run:

    rake stockit:add_stockit_codes
    rake stockit:add_stockit_pallets_boxes
    rake stockit:add_stockit_organisations
    rake stockit:add_stockit_contacts
    rake stockit:add_stockit_activities
    rake stockit:add_stockit_local_orders
    rake stockit:add_designations
    rake stockit:add_stockit_items
    rake goodcity:update_package_image
    rake goodcity:copy_inventory_numbers_used_in_stockit

## Version 0.10

Rake tasks to run:

    rake goodcity:update_set_item_id_for_packages
    rake goodcity:update_package_type_default_location
    rake stockit:add_stockit_countries
    rake stockit:add_designations
    rake stockit:update_stockit_items

## Version 0.11

Rake tasks to run:

    rake goodcity:update_package_favourite_image

## Version 0.12

Rake tasks to run:

    rake goodcity:add_organisation_types
    rake goodcity:add_organisations
    rake goodcity:add_purposes

## Version 0.13

Rake tasks to run:

    rake goodcity:packages_add_received_quantity_data
    rake goodcity:populate_packages_location_data
    rake goodcity:update_orders_packages_data
    rake goodcity:change_allow_web_publish_to_false
