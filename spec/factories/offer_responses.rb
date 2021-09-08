FactoryBot.define do
  factory :offer_response do
    association   :user
    association   :offer
  end
end
