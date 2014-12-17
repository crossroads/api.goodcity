FactoryGirl.define do
  factory :timeslot do
    name_en { generate(:timeslots).first  }
    name_zh_tw { generate(:timeslots).last  }
  end
end
