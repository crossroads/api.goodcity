FactoryBot.define do
  factory :printers_user do
    association   :printer
    association   :user
  end
end
