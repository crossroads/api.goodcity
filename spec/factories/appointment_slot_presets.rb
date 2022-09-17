# frozen_string_literal: true

FactoryBot.define do
  factory :appointment_slot_preset do
    day     { rand(3..6) }
    quota   { 3 }
    hours   { 10 }
    minutes { 0 }
  end

  trait :morning do
    hours   { 10 }
    minutes { 0 }
  end

  trait :afternoon do
    hours   { 14 }
    minutes { 0 }
  end

end
