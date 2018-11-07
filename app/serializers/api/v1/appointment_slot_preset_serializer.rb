module Api::V1
  class AppointmentSlotPresetSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :hours, :minutes, :quota, :day
  end
end
