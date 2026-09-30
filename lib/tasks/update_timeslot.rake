namespace :goodcity do
  # rake goodcity:update_timeslot_labels
  desc 'Rename timeslots to 10:30am-12:30pm and 2pm-4pm'
  task update_timeslot_labels: :environment do
    Timeslot.where("LOWER(name_en) = ?", "10:30am-1pm").update_all(
      name_en: "10:30am-12:30pm",
      name_zh_tw: "上午10:30時至下午12:30時"
    )
    Timeslot.where("LOWER(name_en) = ?", "2pm-4pm").update_all(name_en: "2pm-4pm")
  end

  # rake goodcity:update_delivery_schedule_slotname
  desc 'Update timeslots'
  task update_delivery_schedule_slotname: :environment do
    drop_off_deliveries = Delivery.with_deleted.where(delivery_type: "Drop Off")
    timeslot = Timeslot.find_by(name_en: "10:30AM-1PM")

    drop_off_deliveries.find_in_batches(batch_size: 100).each do |deliveries|
      deliveries.each do |delivery|
        if (schedule = delivery.schedule)
          schedule.slot_name =
            case schedule.slot_name
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
