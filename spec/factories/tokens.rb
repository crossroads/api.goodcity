FactoryGirl.define do
  factory :jwt_token, class: Token do
    ignore do
      token
    end
    initialize_with { new({ bearer: generate(:bearer) }) }
  end
end
