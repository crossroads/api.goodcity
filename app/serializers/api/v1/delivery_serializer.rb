module Api::V1

  class DeliverySerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :start, :finish, :contact_id, :offer_id, :delivery_type,
      :schedule_id

    has_one :contact, serializer: ContactSerializer
    has_one :schedule, serializer: ScheduleSerializer
  end

end
