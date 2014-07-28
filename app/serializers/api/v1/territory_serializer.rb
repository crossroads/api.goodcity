module Api::V1

  class TerritorySerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name
  end

end
