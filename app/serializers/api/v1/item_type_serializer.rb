module Api::V1

  class ItemTypeSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :code

    def name
      object.name
    end

  end

end
