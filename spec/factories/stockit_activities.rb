FactoryGirl.define do
  factory :stockit_activity do
    name {FFaker::Name.first_name}
  end
end
