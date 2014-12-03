module Api::V1

  class ImageSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :favourite, :cloudinary_id, :item_id
  end
end
