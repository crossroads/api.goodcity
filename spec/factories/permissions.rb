FactoryGirl.define do
  factory :permission do
    name            { %w( can_manange_orders can_manage_offers can_manage_packages ).sample }
    initialize_with { Permission.find_or_initialize_by(name: name) } # limits us to our sample of permissions
  end
end
