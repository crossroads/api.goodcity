FactoryGirl.define do
  factory :timeslot do
    name_en { Faker::Name.name  }
    name_zh_tw { Faker::Name.name  }
  end

end
