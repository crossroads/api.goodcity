FactoryGirl.define do
  factory :location do
    building   { [10..45].sample }
    area       { FFaker::Lorem.characters(1) }
    stockit_id { rand(99) }
  end

end
