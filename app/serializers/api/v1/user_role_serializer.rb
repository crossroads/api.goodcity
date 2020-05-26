module Api::V1
  class UserRoleSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :role_id, :user_id

    has_one :user, serializer: UserSerializer, include_user_roles: false
    has_one :role, serializer: RoleSerializer

  end
end
