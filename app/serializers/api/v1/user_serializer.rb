module Api::V1

  class UserSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :mobile, :address_id, :permission_id

    has_one :address, serializer: AddressSerializer
    has_one :permission, serializer: PermissionSerializer

    def mobile
      object.try(:mobile) && object.mobile.slice(4..-1)
    end

    def address_id
      object.address.try(:id)
    end

    def permission_id
      object.permission.try(:id)
    end
  end

end
