module Api::V1
  class UserProfileSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :mobile, :email, :last_connected, :last_disconnected

    has_one :address, serializer: AddressSerializer
    has_one :image, serializer: ImageSerializer
    has_many :user_roles, serializer: UserRoleSerializer

    has_many :organisations_users, serializer: OrganisationsUserSerializer

    def mobile
      object.try(:mobile) && object.mobile.slice(4..-1)
    end
  end
end
