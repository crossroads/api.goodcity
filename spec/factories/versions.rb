FactoryGirl.define do
  factory :version do
    event       { %w(create update).sample }
    whodunnit   {|v| v.association(:user).id }

    trait :with_item do
      association :item
    end

    trait :related_offer do
      related { |v| v.association(:offer)}
    end
  end
end
