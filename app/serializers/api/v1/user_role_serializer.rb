module Api::V1
  class UserRoleSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    embed :ids, include: true

    attributes :id, :role_id
    has_one :user, serializer: UserSerializer
    has_one :role, serializer: RoleSerializer
  end
end
