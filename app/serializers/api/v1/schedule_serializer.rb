module Api::V1
  class ScheduleSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :resource, :scheduled_at, :slot, :slot_name, :zone
  end
end
