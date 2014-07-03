module Api::V1

  class PackageSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :quantity, :length, :width, :height, :notes,
      :item_id, :state, :received_at, :rejected_at, :package_type,
      :created_at, :updated_at

  end

end
