# frozen_String_literal: true

FactoryBot.define do
  factory :packages_location do
    association :package, factory: :package
    location    { Location.find_by!(generate(:location_seed)) }
    quantity    { 1 }
  end
end
