module Api::V1
  class DistrictSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name, :territory_id
    has_one :territory, serializer: TerritoryWithoutDistrictSerializer

    def include_territory?
      @options[:include_territory]
    end

    def name__sql
      "name_#{current_language}"
    end
  end
end
