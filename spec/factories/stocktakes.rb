# frozen_String_literal: true

FactoryBot.define do
  factory :stocktake do
    sequence(:name) { |n| "Stocktake #{n}" }
    state           { 'open' }
    comment         { "Comment" }

    location { Location.find_by!(generate(:location_seed)) }
    association :created_by, factory: :user, strategy: :build

    trait :open do
      state { 'open' }
    end

    trait :closed do
      state { 'closed' }
    end

    trait :cancelled do
      state { 'cancelled' }
    end
  end
end
