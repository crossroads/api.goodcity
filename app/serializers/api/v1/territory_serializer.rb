module Api::V1
  class TerritorySerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name

    has_many :districts, serializer: DistrictSerializer

    def name
      object.try("name_#{current_language}".to_sym)
    end
  end
end
