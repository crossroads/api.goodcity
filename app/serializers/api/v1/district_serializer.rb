module Api::V1

  class DistrictSerializer < CachingSerializer
    embed :ids, include: true
    attributes :id, :name, :territory_id
  end

end
