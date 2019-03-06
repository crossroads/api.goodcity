FactoryBot.define do
  factory :orders_process_checklist do
    association  :order
    association  :process_checklist
  end
end
