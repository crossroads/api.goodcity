module Api::V1

  class DeliverySerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :start, :finish, :contact_id, :offer_id, :delivery_type,
      :schedule_id
  end

end
