FactoryGirl.define do
  factory :stockit_organisation do
    name FFaker::Company.name
    stockit_id 1
  end
end
