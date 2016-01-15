# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :schedule do
    zone { generate(:schedules).keys.sample }
    resource { generate(:schedules)[zone][:resource] }
    slot { generate(:schedules)[zone][:slot] }
    slot_name { generate(:schedules)[zone][:slot_name] }
    scheduled_at { (Time.now + 1.weeks).to_s }

    initialize_with { Schedule.find_or_initialize_by(zone: zone) }

    factory :gogovan_schedule, parent: :schedule do
      resource nil
      slot nil
      slot_name "1:00 PM"
      zone nil
    end

    factory :drop_off_schedule, parent: :schedule do
      resource nil
      slot nil
      slot_name "2PM-4PM"
      zone nil
    end
  end
end
