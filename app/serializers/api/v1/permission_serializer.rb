module Api::V1

  class PermissionSerializer < CachingSerializer
    embed :ids, include: true
    attributes :id, :name
  end

end
