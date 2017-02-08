module Api::V1

  class PackagesLocationSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :package_id, :location_id, :quantity, :item_id

    has_one :location, serializer: LocationSerializer

    def item_id
    end

    def item_id__sql
      'package_id'
    end
  end
end
