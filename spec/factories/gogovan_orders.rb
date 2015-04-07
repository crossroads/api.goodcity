FactoryGirl.define do
  factory :gogovan_order do
    booking_id { rand(1000000..9999999) }
    status "pending"

    trait :active do
      status "active"
    end

    trait :cancelled do
      status "cancelled"
    end

    trait :with_delivery do
      after(:create) do |order|
        create :gogovan_delivery, gogovan_order: order
      end
    end
  end

end
