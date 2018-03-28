module Api::V1
  class UserRoleSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :role_id
    has_one :user, serializer: UserSerializer
  end
end
