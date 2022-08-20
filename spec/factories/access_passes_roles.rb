FactoryBot.define do
  factory :access_passes_role do
    access_pass
    role        { association :role, name: Role::ROLE_NAMES[:stock_fulfilment] }
  end
end
