module Api::V1
  class AppointmentSlotSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :timestamp, :quota
  end
end
  