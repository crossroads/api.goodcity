# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :schedule do
    id { generate(:schedules).keys.sample }
    resource { generate(:schedules)[id][:resource] }
    slot { generate(:schedules)[id][:slot_id] }
    slot_name { generate(:schedules)[id][:slot_name] }
    zone { generate(:schedules)[id][:zone] }
    scheduled_at {Time.now + 1.weeks + generate(:schedules)[id][:scheduled_at].day}
  end
end
