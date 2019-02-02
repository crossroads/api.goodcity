FactoryBot.define do
  factory :version do
    event       { %w(create update).sample }
    whodunnit   {|v| v.association(:user).id }
    association :item # required

    trait :related_offer do
      related { |v| v.association(:offer)}
    end
  end
end
