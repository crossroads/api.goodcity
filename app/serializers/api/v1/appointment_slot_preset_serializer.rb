module Api::V1
  class AppointmentSlotPresetSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :hours, :minutes, :quota, :day
  end
end
  