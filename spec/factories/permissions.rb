# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :permission do
    name            { %w( Reviewer Supervisor Administrator ).sample }
    initialize_with { Permission.find_or_initialize_by(name: name) } # limits us to our sample of permissions
  end

  factory :reviewer_permission, parent: :permission do
    name 'Reviewer'
  end

  factory :supervisor_permission, parent: :permission do
    name 'Supervisor'
  end

  factory :administrator_permission, parent: :permission do
    name 'Administrator'
  end

  factory :system_permission, parent: :permission do
    name 'System'
  end

end
