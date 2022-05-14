FactoryBot.define do
  factory :timeslot do
    sequence(:name_en) { |n| "Timeslot #{n}" }
    name_zh_tw         { name_en }
  end
end
