# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :address do
    sequence(:flat)     { |n| "Flat #{n}" }
    sequence(:building) { |n| "Building #{n}" }
    sequence(:street)   { |n| "Street #{n}" }
    association         :district
    address_type        { 'Collection' }
    association         :addressable, factory: :contact, strategy: :build
    addressable_type    { 'Contact' }
    notes               { 'Notes for driver' }
  end

  factory :profile_address, parent: :address do
    address_type     { 'profile' }
    association      :addressable, factory: :user, strategy: :build
    addressable_type { 'User' }
  end

  factory :gogovan_collection_address, class: Address do
    association      :district
    address_type     { 'Collection' }
    association      :addressable, factory: :contact, strategy: :build
    addressable_type { 'Contact' }
  end
end
