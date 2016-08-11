# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item do
    donor_description { FFaker::Lorem.sentence }
    state             'submitted'

    association :donor_condition
    association :package_type
    association :offer

    trait :draft do
      donor_description nil
      state             'draft'
    end

    trait :with_packages do
      packages { create_list(:package, 2) }
    end

    trait :with_inventory_packages do
      after(:create) do |item|
        create_list(:package, 2, :with_set_item, item: item)
      end
    end

    trait :with_received_packages do
      packages { create_list(:package, 2, state: :received) }
    end

    trait :with_images do
      images { create_list(:image, 1) << create(:image, favourite: true) }
    end

    trait :paranoid do
      state  { ["submitted", "accepted", "rejected"].sample }
      images { create_list(:image, 2) }
    end

    trait :with_messages do
      transient do
        messages_count 1
      end

      after(:create) do |item, evaluator|
        create_list(:message, evaluator.messages_count,
          sender: item.offer.created_by,
          offer: item.offer,
          item: item)
      end
    end

    trait :rejected do
      state              'rejected'
      association        :rejection_reason
      association        :offer, :under_review
      reject_reason      { FFaker::Lorem.sentence }
      rejection_comments { FFaker::Lorem.sentence }
    end
  end
end
