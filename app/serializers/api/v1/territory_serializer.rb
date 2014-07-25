module Api::V1

  class TerritorySerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :name_zh_tw
  end

end
