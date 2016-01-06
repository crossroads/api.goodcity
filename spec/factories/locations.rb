FactoryGirl.define do
  factory :location do
    building    { FFaker::Lorem.word }
    area        { FFaker::Lorem.word }
    stockit_id  { rand(99) }
  end

end
