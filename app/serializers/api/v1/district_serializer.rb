module Api::V1
  class DistrictSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :territory_id
    attribute "name_#{current_language}".to_sym
    has_one :territory, serializer: TerritoryWithoutDistrictSerializer

    def include_territory?
      @options[:include_territory]
    end
  end
end
