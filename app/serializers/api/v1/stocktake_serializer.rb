module Api
  module V1
    class StocktakeSerializer < ApplicationSerializer
      embed :ids, include: true

      has_many  :stocktake_revisions, serializer: StocktakeRevisionSerializer
      has_one   :location, serializer: LocationSerializer
      has_one   :created_by, serializer: UserSerializer
      
      attributes :id, :name, :location_id, :state, :created_at:, :updated_at
    end
  end
end
