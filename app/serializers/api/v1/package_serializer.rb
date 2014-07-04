module Api::V1

  class PackageSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :quantity, :length, :width, :height, :notes,
      :item_id, :state, :received_at, :rejected_at,
      :created_at, :updated_at

    has_one :package_type, serializer: ItemTypeSerializer
  end

end
