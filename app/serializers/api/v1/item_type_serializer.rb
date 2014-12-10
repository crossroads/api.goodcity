module Api::V1

  class ItemTypeSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :code, :parent_id, :is_item_type_node
  end

end
