module Api::V1
  class ContactSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name, :mobile, :mobile_phone_number
    has_one :address, serializer: AddressSerializer

    def mobile_phone_number
      object.mobile
    end

    def mobile_phone_number__sql
      'mobile'
    end
  end
end
