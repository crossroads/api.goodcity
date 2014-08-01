# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item do
    donor_description      { Faker::Lorem.sentence }
    donor_condition        { create :donor_condition }
    state                  'draft'
    item_type_id           { create(:item_type).id }
    rejection_reason_id    { create(:rejection_reason).id }
    rejection_other_reason { Faker::Lorem.sentence }
    packages               { create_list(:package, (rand(2)+1)) }
  end
end
