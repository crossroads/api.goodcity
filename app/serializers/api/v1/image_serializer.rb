module Api::V1

  class ImageSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :favourite, :cloudinary_id, :item_id, :angle

    def item_id
      object.imageable_id
    end

    def item_id__sql
      "imageable_id"
    end
  end
end
