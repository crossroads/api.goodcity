namespace :goodcity do

  # rake goodcity:update_timeslots
  desc 'Update timeslots'
  task update_timeslots: :environment do
    Timeslot.where("name_en <> ?", "2PM-4PM").delete_all

    FactoryGirl.create :timeslot,
      name_en: "10:30AM-1PM",
      name_zh_tw: "上午10:30時至下午1時"
  end

  # rake goodcity:update_delivery_schedule_slotname
  desc 'Update timeslots'
  task update_delivery_schedule_slotname: :environment do
    drop_off_deliveries = Delivery.where(delivery_type: "Drop Off")
    timeslot = Timeslot.find_by(name_en: "10:30AM-1PM")

    drop_off_deliveries.find_in_batches(batch_size: 10).each do |deliveries|
      deliveries.each do |delivery|
        if schedule = delivery.schedule
          schedule.slot_name = case schedule.slot_name
            when "9AM-11AM" then "10:30AM-1PM"
            when "11AM-1PM" then "10:30AM-1PM"
            when "上午9時至上午11時" then "上午10:30時至下午1時"
            when "上午11時至下午1時" then "上午10:30時至下午1時"
            else schedule.slot_name
            end
          schedule.slot = timeslot.id if schedule.slot_name_changed?
          schedule.save
        end
      end
    end
  end
end
