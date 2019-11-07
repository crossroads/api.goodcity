FactoryBot.define do
  factory :packages_inventory do
    action        'inventory'
    quantity      1
    created_at    { Time.now }
    association   :package
    association   :location
    association   :user

    trait :loss do
      action    "loss"
      quantity  (-5)
    end

    trait :gain do
      action    "gain"
      quantity  (5)
    end

    trait :move do
      action    "move"
      quantity  (5)
    end

    trait :inventory do
      action    "inventory"
      quantity  (5)
    end

    trait :dispatch do
      action    "dispatch"
      quantity  (-5)
    end

    trait :undispatch do
      action    "undispatch"
      quantity  (5)
    end
  end
end
