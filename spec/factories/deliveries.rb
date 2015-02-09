FactoryGirl.define do
  factory :delivery do
    offer
    contact
    schedule
    delivery_type { [ "Alternate", "Drop Off", "Gogovan"].sample }
  end
end
