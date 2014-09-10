module Api::V1

  class UserSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :mobile

    has_many :permissions, serializer: PermissionSerializer
    has_one :address, serializer: AddressSerializer

    def mobile
      object.try(:mobile) && object.mobile.slice!(4..-1)
    end
  end

end
