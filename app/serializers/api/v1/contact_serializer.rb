module Api::V1

  class ContactSerializer < CachingSerializer
    embed :ids, include: true
    attributes :id, :name, :mobile
    has_one :address, serializer: AddressSerializer
  end

end
