FactoryBot.define do
  factory :access_passes_role do
    access_pass

    before(:create) do |access_passes_role|
      access_passes_role.role = Role.find_by(name: Role::ROLE_NAMES[:stock_fulfilment])
    end
  end
end
