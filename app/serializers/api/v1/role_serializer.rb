module Api::V1
  class RoleSerializer < ApplicationSerializer
    has_many :user_roles, serializer: UserRoleSerializer
    has_many :role_permissions, serializer: RolePermissionSerializer
  end
end
