module Api::V1

  class ScheduleSerializer < ApplicationSerializer
    include SerializeTimeValue

    embed :ids, include: true
    attributes :id, :resource, :scheduled_at, :slot, :slot_name, :zone

    # has_many :deliveries, serializer: DeliverySerializer
  end

end
