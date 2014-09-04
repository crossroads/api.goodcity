module Api::V1

  class PermissionSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name
  end

end
