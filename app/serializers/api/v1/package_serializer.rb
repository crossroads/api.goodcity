module Api::V1

  class PackageSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer

    attributes :id, :quantity, :length, :width, :height, :notes,
      :item_id, :state, :received_at, :rejected_at, :inventory_number,
      :created_at, :updated_at, :package_type_id, :image_id, :offer_id
  end

end
