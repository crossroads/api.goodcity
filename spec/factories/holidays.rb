FactoryBot.define do
  factory :holiday do
    sequence(:name) { |n| "Holiday #{n}" }
    holiday         { Time.zone.now + 5.days }
    year            { Time.zone.now.year }
  end
end
