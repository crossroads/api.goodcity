module Api::V1

  class ItemTypeSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name, :code, :parent_id, :is_item_type_node

    def name__sql
      "name_#{current_language}"
    end
  end

end
