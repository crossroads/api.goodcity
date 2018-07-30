FactoryBot.define do
  factory :permission do
    name            { generate(:permissions_roles).values.flatten.uniq.sample }
    initialize_with { Permission.find_or_initialize_by(name: name) } # limits us to our sample of permissions

    trait :api_write do
      name 'api-write'
    end
  end
end
