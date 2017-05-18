module Api::V1

  class BrowseItemSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :created_at, :updated_at,
      :package_type_id, :donor_condition_id

    has_one :package_type, serializer: PackageTypeSerializer

  end
end
