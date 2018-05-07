module Api::V1
  class PermissionSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    embed :ids, include: true
    attributes :id, :name
  end
end
