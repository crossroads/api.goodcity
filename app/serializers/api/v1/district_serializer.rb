module Api::V1

  class DistrictSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :territory_id
  end

end
