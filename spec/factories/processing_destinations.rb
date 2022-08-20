FactoryBot.define do
  factory :processing_destination do
    sequence(:name) { |n| "Processing destination #{n}" }
  end
end
