# frozen_String_literal: true

FactoryBot.define do
  factory :organisations_user do
    association :organisation, factory: :organisation
    association :user, factory: :user
    position    { 'Employee' }
    status      { 'approved' }
    preferred_contact_number { generate(:phone_number) }

    [:pending, :approved, :expired, :denied].each do |status_name|
      trait status_name do
        status { status_name.to_s }
      end
    end
  end
end
