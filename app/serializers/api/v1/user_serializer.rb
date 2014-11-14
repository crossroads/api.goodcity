module Api::V1

  class UserSerializer < CachingSerializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :mobile

    has_one :address, serializer: AddressSerializer
    has_one :permission, serializer: PermissionSerializer

    def mobile
      object.try(:mobile) && object.mobile.slice(4..-1)
    end

  end

end
