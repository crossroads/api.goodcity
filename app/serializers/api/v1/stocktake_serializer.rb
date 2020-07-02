module Api
  module V1
    class StocktakeSerializer < ApplicationSerializer
      embed :ids, include: true

      has_many :stocktake_revisions, serializer: StocktakeRevisionSerializer
      has_one :location, serializer: LocationSerializer
      
      attributes :id, :name, :location_id, :state
    end
  end
end
