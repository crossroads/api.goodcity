FactoryBot.define do
  factory :stocktake_revision do
    quantity { 0 }
    state { "pending" }
    warning_en { "" }
    warning_zh_tw { "" }
    dirty { false }

    association :stocktake
    association :package
  end
end
