module Api::V1

  class DeliverySerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :start, :finish, :offer_id, :delivery_type

    has_one :contact, serializer: ContactSerializer
    has_one :schedule, serializer: ScheduleSerializer
    has_one :gogovan_order, serializer: GogovanOrderSerializer
  end

end
