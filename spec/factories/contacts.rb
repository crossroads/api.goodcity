# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    name { FFaker::Name.name }
    mobile { generate(:mobile) }
  end

  factory :contact_with_address, parent: :contact do
    after(:create) do |contact|
      create :address, addressable: contact
    end
  end

  factory :gogovan_contact, parent: :contact do
    after(:create) do |contact|
      create :gogovan_collection_address, addressable: contact
    end
  end
end
