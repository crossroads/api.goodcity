FactoryGirl.define do
  factory :delivery do
    offer
    contact
    delivery_type { ["Alternate", "Drop Off", "Gogovan"].sample }
  end
end
