module Api::V1

  class TerritorySerializer < CachingSerializer
    embed :ids, include: true
    attributes :id, :name
    has_many :districts, serializer: DistrictSerializer
  end

end
