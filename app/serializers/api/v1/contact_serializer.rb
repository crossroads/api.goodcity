module Api::V1

  class ContactSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :mobile, :address_id

    has_one :address, serializer: AddressSerializer

    def address_id
      object.address.try(:id)
    end
  end

end
