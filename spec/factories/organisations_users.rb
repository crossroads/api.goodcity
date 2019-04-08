FactoryBot.define do
  factory :organisations_user do
    association :organisation, factory: :organisation
    association :user, factory: :user
    position "MyString"
    preferred_contact_number { generate(:phone_number) }
  end
end
