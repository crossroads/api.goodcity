FactoryGirl.define do
  factory :order do
    status   ["draft", "submitted", "processing", "closed", "cancelled"].sample
    state    ["draft", "submitted", "processing", "closed", "cancelled"].sample

    code          { generate(:code) }
    detail_type   ["CarryOut", "Shipment", "StockitLocalOrder", "Goodcity"].sample

    description     FFaker::Lorem.sentence
    purpose_description FFaker::Lorem.sentence
    stockit_id      nil
    association     :detail, factory: :stockit_local_order  , strategy: :create
    association     :stockit_organisation
    association     :stockit_activity
    association     :organisation
    association     :stockit_contact
    association     :country

    trait :with_created_by do
      association :created_by, factory: :user, strategy: :build
    end

    trait :with_processed_by do
      association :processed_by, factory: :user, strategy: :build
    end
  end
end
