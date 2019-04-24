FactoryBot.define do
  factory :gogovan_order do
    booking_id { rand(1000000..9999999) }
    status "pending"
    driver_name    { FFaker::Name.name }
    driver_mobile  { generate(:mobile) }
    driver_license { FFaker::Identification.drivers_license }

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
