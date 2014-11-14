module Api::V1

  class ImageSerializer < CachingSerializer
    embed :ids, include: true

    attributes :id, :image_url, :thumb_image_url, :favourite, :order, :image_id

    def image_url
      object.image_url
    end

    def thumb_image_url
      object.thumb_image_url
    end

  end
end
