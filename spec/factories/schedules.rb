# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :schedule do
    id { generate(:schedules).keys.sample }
    resource { generate(:schedules)[id][:resource] }
    slot { generate(:schedules)[id][:slot] }
    slot_name { generate(:schedules)[id][:slot_name] }
    zone { generate(:schedules)[id][:zone] }
    scheduled_at { (Time.now + 1.weeks + generate(:schedules)[id][:scheduled_at].day).to_s }

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
