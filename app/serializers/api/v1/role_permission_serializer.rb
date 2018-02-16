module Api::V1
  class RolePermissionSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :role_id
    has_one :permission, serializer: PermissionSerializer
  end
end
