module Api::V1

  class ContactSerializer < ActiveModel::Serializer
    # embed :ids, include: true
    attributes :id, :name, :mobile

    has_one :delivery, Serializer: DeliverySerializer
  end

end
