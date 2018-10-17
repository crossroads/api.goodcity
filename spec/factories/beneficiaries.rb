FactoryBot.define do
  factory :beneficiary do
    identity_type { create(:identity_type) }
    identity_number "7359"
    title "Mr"
    first_name "John"
    last_name "Doe"
    phone_number "36453837"
    created_at "2018-09-28 11:10:17"
    updated_at "2018-09-28 11:10:17"

    trait :with_created_by do
      association :created_by, factory: :user, strategy: :build
    end

  end
end
