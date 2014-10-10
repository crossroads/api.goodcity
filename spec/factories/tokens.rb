FactoryGirl.define do
  factory :jwt_token, class: Token do
    initialize_with { new({ bearer: generate(:bearer) }) }
  end
end
