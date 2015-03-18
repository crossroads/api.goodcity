module Api::V1

  class ScheduleSerializer < ApplicationSerializer

    embed :ids, include: true
    attributes :id, :resource, :scheduled_at, :slot, :slot_name, :zone

    # has_many :deliveries, serializer: DeliverySerializer

    def scheduled_at__sql
      " schedules.scheduled_at#{time_zone_query} "
    end
  end

end
