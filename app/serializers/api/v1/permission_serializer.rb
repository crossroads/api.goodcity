module Api::V1

  class PermissionSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name
  end

end
