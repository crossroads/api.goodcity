FactoryGirl.define do
  factory :role do
    name { %w( Reviewer Supervisor Administrator ).sample }
  end
end
