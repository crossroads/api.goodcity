FactoryBot.define do
  factory :stockit_activity do
    sequence(:name) { |n| "Stockit activity #{n}" }
  end
end
