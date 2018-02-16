module Api::V1
  class UserRoleSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id

    has_one :user, serializer: UserSerializer
    has_one :role, serializer: RoleSerializer
  end
end
