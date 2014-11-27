module Api::V1

  class ItemTypeSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :code, :parent_id
  end

end
