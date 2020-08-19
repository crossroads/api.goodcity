module Api::V1
  class DistrictSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :territory_id, :name
    has_one :territory, serializer: TerritoryWithoutDistrictSerializer

    def name
      object.try("name_#{current_language}".to_sym)
    end

    def include_territory?
      @options[:include_territory]
    end
  end
end
