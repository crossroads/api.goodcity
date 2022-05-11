# frozen_String_literal: true

FactoryBot.define do
  factory :identity_type do
    sequence(:identifier) { |n| generate(:identity_types).keys.sort[n%generate(:identity_types).keys.size] }
    name_en               { generate(:identity_types)[identifier][:name_en] }
    name_zh_tw            { generate(:identity_types)[identifier][:name_zh_tw] }
    initialize_with       { IdentityType.find_or_initialize_by(identifier: identifier) }
  end
end
