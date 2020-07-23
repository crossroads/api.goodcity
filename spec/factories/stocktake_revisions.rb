FactoryBot.define do
  factory :stocktake_revision do
    quantity { 0 }
    state { "pending" }
    warning { "" }
    dirty { false }

    association :stocktake
    association :package
  end
end
