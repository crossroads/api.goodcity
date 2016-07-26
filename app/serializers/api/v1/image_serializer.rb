module Api::V1

  class ImageSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :favourite, :cloudinary_id, :item_id, :angle
  end
end
