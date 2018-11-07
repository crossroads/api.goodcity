FactoryBot.define do
    factory :appointment_slot do
      timestamp { DateTime.now }
      quota 3
      note ""
    end
  end
  