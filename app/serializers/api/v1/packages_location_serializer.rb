module Api::V1

  class PackagesLocationSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :package_id, :location_id, :quantity

    has_one :location, serializer: LocationSerializer
  end
end
