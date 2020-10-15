# frozen_String_literal: true

FactoryBot.define do
  factory :packages_inventory do
    action        { 'inventory' }
    quantity      { 1 }
    created_at    { Time.now }
    association   :package
    association   :location
    association   :user

    trait :loss do
      action    { 'loss' }
      quantity  { -5 }
    end

    trait :gain do
      action    { 'gain' }
      quantity  { 5 }
    end

    trait :process do
      action    { 'process' }
      quantity  { -5 }
    end

    trait :unprocess do
      action    { 'unprocess' }
      quantity  { 5 }
    end

    trait :pack do
      action    { 'pack' }
      quantity  { -5 }
    end

    trait :unpack do
      action    { 'unpack' }
      quantity  { 5 }
    end

    trait :trash do
      action    { 'trash' }
      quantity  { -5 }
    end

    trait :untrash do
      action    { 'untrash' }
      quantity  { 5 }
    end

    trait :recycle do
      action    { 'recycle' }
      quantity  { -5 }
    end

    trait :preserve do
      action    { 'preserve' }
      quantity  { 5 }
    end

    trait :move do
      action    { 'move' }
      quantity  { 5 }
    end

    trait :inventory do
      action    { 'inventory' }
      quantity  { 5 }
    end

    trait :dispatch do
      action    { 'dispatch' }
      quantity  { -5 }
    end

    trait :undispatch do
      action    { 'undispatch' }
      quantity  { 5 }
    end
  end
end
