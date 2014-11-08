module Api::V1

  class TerritorySerializer < ActiveModel::Serializer
    cached
    delegate :cache_key, to: :object

    embed :ids, include: true
    attributes :id, :name

    has_many :districts, serializer: DistrictSerializer
  end

end
