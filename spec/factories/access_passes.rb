FactoryBot.define do
  factory :access_pass do
    printer
    association :generated_by, factory: :user
    access_expires_at { Time.current.at_end_of_day }
    access_key { '123456' }

    trait :with_roles do
      after(:create) do |pass|
        create :access_pass_role, access_pass: pass
      end
    end

    trait :expired do
      after(:create) do |pass|
        pass.update_column(:generated_at, 10.minutes.ago)
      end
    end
  end
end
