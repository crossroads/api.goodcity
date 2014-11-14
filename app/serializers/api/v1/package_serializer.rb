module Api::V1

  class PackageSerializer < CachingSerializer
    embed :ids, include: true

    attributes :id, :quantity, :length, :width, :height, :notes,
      :item_id, :state, :received_at, :rejected_at,
      :created_at, :updated_at, :package_type_id

  end

end
