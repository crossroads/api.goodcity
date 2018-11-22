FactoryBot.define do
    factory :appointment_slot_preset do
      day { rand(1..7) }
      quota 3
      minutes 30
      hours 14
    end
  end
  