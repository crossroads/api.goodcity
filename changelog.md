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

    rake goodcity:add_stockit_locations
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
    rake goodcity:update_packages

## Version 0.8

Rake tasks to run:

    rake goodcity:update_timeslots
    rake goodcity:update_delivery_schedule_slotname
    rake goodcity:update_items_saleable_field

## Version 0.9

Rake tasks to run:

    rake goodcity:add_stockit_codes
