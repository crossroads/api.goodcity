FactoryGirl.define do
  factory :organisations_user do
    association     :organisation, factory: :organisation
    association     :user, factory: :user
    position "MyString"
  end
end
