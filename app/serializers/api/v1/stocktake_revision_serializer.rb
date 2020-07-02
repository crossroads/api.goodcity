module Api
  module V1
    class StocktakeRevisionSerializer < ApplicationSerializer
      embed :ids, include: true

      has_one :package, serializer: PackageSerializer
      
      attributes :id, :stocktake_id, :package_id, :warning_en, :warning_zh_tw, :state, :quantity
    end
  end
end
