# frozen_String_literal: true

FactoryBot.define do
  factory :appointment_slot do
    timestamp { DateTime.now }
    quota     { 3 }
    note      { 'Appointment slot' }
  end
end
