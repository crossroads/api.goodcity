module Api::V1
  class RoleSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :name

    has_many :role_permissions, serializer: RolePermissionSerializer
    has_many :user_roles, serializer: UserRoleSerializer
  end
end
