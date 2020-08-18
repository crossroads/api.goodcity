module Api::V1
  class UserProfileSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :mobile, :email, :last_connected, :last_disconnected, :is_email_verified, :is_mobile_verified, :disabled, :max_role_level, :preferred_language

    has_one :address, serializer: AddressSerializer
    has_one :image, serializer: ImageSerializer
    has_many :user_roles, serializer: UserRoleSerializer

    has_many :organisations_users, serializer: OrganisationsUserSerializer

    def mobile
      object.try(:mobile) && object.mobile.slice(4..-1)
    end

    def max_role_level__sql
      "(SELECT MAX(roles.level) FROM roles INNER JOIN user_roles ON roles.id = user_roles.role_id WHERE user_roles.user_id = users.id)"
    end

    def max_role_level
      object.max_role_level
    end
  end
end
