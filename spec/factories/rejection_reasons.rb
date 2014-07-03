# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :rejection_reason do
    name            { %w( Quality Size Other ).sample }
    initialize_with { RejectionReason.find_or_initialize_by(name: name) }
  end
end
