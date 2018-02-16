module Api::V1
  class RolePermissionSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :role, serializer: RoleSerializer
    has_one :permission, serializer: PermissionSerializer
  end
end
