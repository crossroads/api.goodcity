FactoryBot.define do
  factory :offers_package do
    association   :offer
    association   :package
  end
end
