FactoryGirl.define do
  factory :delivery do
    association :offer, :scheduled
    delivery_type { ["Alternate", "Drop Off", "Gogovan"].sample }

    factory :crossroads_delivery do
      association :contact, factory: :contact_with_address
      schedule
      delivery_type { "Alternate" }
    end

    factory :gogovan_delivery do
      association :contact, factory: :gogovan_contact
      association :schedule, factory: :gogovan_schedule
      gogovan_order
      delivery_type { "Gogovan" }
    end

    factory :drop_off_delivery do
      association :schedule, factory: :drop_off_schedule
      delivery_type { "Drop Off" }
    end
  end
end
