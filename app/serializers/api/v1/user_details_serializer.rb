module Api::V1
  class UserDetailsSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :first_name, :last_name, :mobile, :title,
      :created_at, :last_connected, :last_disconnected, :email,
      :is_email_verified, :is_mobile_verified, :disabled, :preferred_language,
      :organisations_users_ids

    has_one :image, serializer: ImageSerializer
    has_one :address, serializer: AddressSerializer
    has_many :printers_users, serializer: PrintersUserSerializer
    has_many :user_roles, serializer: UserRoleSerializer
    has_many :organisations_users, serializer: OrganisationsUserSerializer


    def organisations_users_ids
      object.organisations_users.pluck(:id)
    end
  end
end
