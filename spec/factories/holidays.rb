FactoryGirl.define do
  factory :holiday do
    holiday { Time.zone.now + 5.days }
    year { Time.zone.now.year }
  end
end
