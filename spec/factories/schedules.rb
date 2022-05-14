# frozen_String_literal: true

FactoryBot.define do
  factory :schedule do
    sequence(:zone)      { |n| "Zone #{n}" }
    sequence(:resource)  { |n| "Truck #{n}" }
    sequence(:slot)      { |n| n }
    sequence(:slot_name) { |n| "Slot #{n}" }
    scheduled_at         { (Time.now + 1.weeks).to_s }

    factory :gogovan_schedule, parent: :schedule do
      zone      { nil }
      resource  { nil }
      slot      { nil }
      slot_name { '1:00 PM' }
    end

    factory :drop_off_schedule, parent: :schedule do
      zone      { nil }
      resource  { nil }
      slot      { nil }
      slot_name { '2PM-4PM' }
    end
  end
end
