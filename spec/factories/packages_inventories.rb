FactoryBot.define do
  factory :packages_inventory do
    quantity       1
    action        'inventory'
    created_at    { Time.now }
    association   :package
    association   :location
    association   :user
  end
end
